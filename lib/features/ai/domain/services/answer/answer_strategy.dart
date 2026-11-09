import '../../entities/chat_turn.dart';
import '../../entities/retrieved_chunk.dart';
import '../chat/chat_prompt_builder.dart';
import '../gemma/gemma_manager.dart';
import 'device_capability.dart';

/// Produces the answer to a question from already-retrieved context.
abstract interface class AnswerStrategy {
  Stream<String> answer({
    required String question,
    required List<RetrievedChunk> chunks,
    List<ChatTurn> history,
  });
}

/// Full on-device LLM answer via Gemma.
class GemmaAnswerStrategy implements AnswerStrategy {
  GemmaAnswerStrategy({required this.promptBuilder, required this.gemma});

  final ChatPromptBuilder promptBuilder;
  final GemmaManager gemma;

  @override
  Stream<String> answer({
    required String question,
    required List<RetrievedChunk> chunks,
    List<ChatTurn> history = const [],
  }) async* {
    final prompt = promptBuilder.build(
      question: question,
      chunks: chunks,
      history: history,
    );
    final tokens = await gemma.generateResponse(
      prompt,
      systemInstruction: promptBuilder.systemInstruction,
    );
    yield* tokens;
  }
}

/// "Lite mode": no LLM. Answers with the most relevant facts retrieved from
/// the user's own data. Runs on any device, instantly, with zero RAM cost.
class TemplateAnswerStrategy implements AnswerStrategy {
  const TemplateAnswerStrategy({this.maxFacts = 4});

  final int maxFacts;

  static const liteNote =
      '(Lite mode: your phone has limited memory, so I\'m showing the '
      'matching facts from your data instead of a written answer.)';

  static const nothingFound =
      'I couldn\'t find anything in your expenses that matches that. '
      'Try asking about a category, a month, a merchant or a budget.';

  @override
  Stream<String> answer({
    required String question,
    required List<RetrievedChunk> chunks,
    List<ChatTurn> history = const [],
  }) async* {
    final facts = <String>[];
    for (final c in chunks) {
      final text = c.chunk.text.trim();
      if (text.isNotEmpty && !facts.contains(text)) facts.add(text);
      if (facts.length == maxFacts) break;
    }

    if (facts.isEmpty) {
      yield nothingFound;
      return;
    }

    yield 'Here\'s what I found in your data:\n';
    for (final fact in facts) {
      yield '• $fact\n';
    }
    yield '\n$liteNote';
  }
}

/// Uses [primary] (Gemma) when the device has enough RAM, otherwise
/// [fallback]. Also falls back when the primary fails before emitting
/// anything (model missing, out of memory, engine error); failures midway
/// through an answer are surfaced, since the user has already seen part of
/// it.
class AdaptiveAnswerStrategy implements AnswerStrategy {
  AdaptiveAnswerStrategy({
    required this.primary,
    required this.fallback,
    required this.device,
    this.minRamMb = 3000,
    this.onFallback,
  });

  final AnswerStrategy primary;
  final AnswerStrategy fallback;
  final DeviceCapability device;

  /// Below this, Gemma is skipped. Phones sold as "3 GB" report ~2.7–2.9 GB.
  final int minRamMb;

  /// Diagnostics hook (e.g. logging) when the fallback is used.
  final void Function(Object reason)? onFallback;

  bool? _capable;

  Future<bool> _isCapable() async {
    final cached = _capable;
    if (cached != null) return cached;
    final ram = await device.totalRamMb();
    // Unknown RAM: try Gemma and rely on the error fallback.
    return _capable = ram == null || ram >= minRamMb;
  }

  @override
  Stream<String> answer({
    required String question,
    required List<RetrievedChunk> chunks,
    List<ChatTurn> history = const [],
  }) async* {
    if (!await _isCapable()) {
      onFallback?.call('low-ram');
      yield* fallback.answer(
        question: question,
        chunks: chunks,
        history: history,
      );
      return;
    }

    var emitted = false;
    try {
      await for (final token in primary.answer(
        question: question,
        chunks: chunks,
        history: history,
      )) {
        emitted = true;
        yield token;
      }
    } catch (error) {
      if (emitted) rethrow;
      onFallback?.call(error);
      yield* fallback.answer(
        question: question,
        chunks: chunks,
        history: history,
      );
    }
  }
}
