import '../services/answer/answer_strategy.dart';
import '../services/retrieval/retrieval_service.dart';
import '../services/safety/ai_safety_policy.dart';
import '../entities/chat_turn.dart';

/// Retrieval-augmented chat pipeline.
///
/// Chains the full question-answering flow:
///
/// 1. rejects unsafe questions via [AiSafetyPolicy] (emitting a canned
///    template response instead),
/// 2. answers "Can I afford it?"-style questions directly from budgets
///    via [directAnswer], when provided,
/// 3. embeds the question and retrieves the most relevant chunks via
///    [RetrievalService],
/// 4. produces the answer via [AnswerStrategy] — Gemma on capable devices,
///    a retrieval-only "lite" answer on low-memory devices or when the model
///    fails to start.
///
/// The returned stream emits response tokens; the final answer is the
/// concatenation of every emitted token. Errors raised at any stage surface
/// as errors on the returned stream.
class AskQuestionUseCase {
  AskQuestionUseCase({
    required this.retrievalService,
    required this.answerStrategy,
    required this.safetyPolicy,
    this.directAnswer,
  });

  final RetrievalService retrievalService;
  final AnswerStrategy answerStrategy;
  final AiSafetyPolicy safetyPolicy;

  /// Optional deterministic answerer tried before retrieval (e.g. "Can I
  /// afford it?"). Returns `null` to let the RAG pipeline answer.
  final Future<String?> Function(String question)? directAnswer;

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

    final direct = await directAnswer?.call(question);
    if (direct != null) {
      yield direct;
      return;
    }

    final chunks = await retrievalService.retrieve(
      query: question,
      topK: topK,
      minScore: minScore,
    );

    yield* answerStrategy.answer(
      question: question,
      chunks: chunks,
      history: history,
    );
  }
}
