import 'package:flutter/foundation.dart';

import '../services/chat/chat_prompt_builder.dart';
import '../services/gemma/gemma_manager.dart';
import '../services/retrieval/retrieval_service.dart';
import '../services/safety/ai_safety_policy.dart';
import '../entities/chat_turn.dart';

/// Retrieval-augmented chat pipeline.
///
/// Chains the full question-answering flow:
///
/// 1. rejects unsafe questions via [AiSafetyPolicy] (emitting a canned
///    template response instead),
/// 2. embeds the question and retrieves the most relevant chunks via
///    [RetrievalService],
/// 3. builds a prompt from those chunks via [ChatPromptBuilder],
/// 4. streams the Gemma response token by token via [GemmaManager].
///
/// The returned stream emits response tokens; the final answer is the
/// concatenation of every emitted token. Errors raised at any stage surface
/// as errors on the returned stream.
class AskQuestionUseCase {
  AskQuestionUseCase({
    required this.retrievalService,
    required this.promptBuilder,
    required this.gemmaManager,
    required this.safetyPolicy,
  });

  final RetrievalService retrievalService;
  final ChatPromptBuilder promptBuilder;
  final GemmaManager gemmaManager;
  final AiSafetyPolicy safetyPolicy;

  /// Streams the answer to [question], retrieving up to [topK] chunks with a
  /// minimum cosine similarity of [minScore].
  ///
  /// [history] carries prior turns so the model can answer follow-up
  /// questions with conversational context.
  Stream<String> call(
    String question, {
    int topK = RetrievalService.defaultTopK,
    double minScore = 0.0,
    List<ChatTurn> history = const [],
  }) async* {
    if (question.trim().isEmpty) {
      throw ArgumentError.value(question, 'question', 'Must not be blank.');
    }

    final verdict = safetyPolicy.assess(question);
    if (!verdict.isAllowed) {
      yield verdict.template!;
      return;
    }

    final chunks = await retrievalService.retrieve(
      query: question,
      topK: topK,
      minScore: minScore,
    );
    if (kDebugMode) {
      debugPrint(
        '[AskQuestion] retrieved ${chunks.length} chunk(s) for "$question":',
      );
      for (final result in chunks) {
        debugPrint(
          '  id=${result.chunk.id} [${result.chunk.chunkType}] '
          '(sim ${result.similarity.toStringAsFixed(3)}) '
          '${result.chunk.text}',
        );
      }
    }
    final prompt = promptBuilder.build(
      question: question,
      chunks: chunks,
      history: history,
    );
    final tokens = await gemmaManager.generateResponse(
      prompt,
      systemInstruction: promptBuilder.systemInstruction,
    );

    await for (final token in tokens) {
      yield token;
    }
  }
}
