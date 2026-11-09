import 'package:expense_flow_app/features/ai/domain/entities/chat_turn.dart';
import 'package:expense_flow_app/features/ai/domain/entities/embedding_chunk.dart';
import 'package:expense_flow_app/features/ai/domain/entities/retrieved_chunk.dart';
import 'package:expense_flow_app/features/ai/domain/services/answer/answer_strategy.dart';
import 'package:expense_flow_app/features/ai/domain/services/answer/device_capability.dart';
import 'package:flutter_test/flutter_test.dart';

class _Ram implements DeviceCapability {
  _Ram(this.mb);
  final int? mb;
  int calls = 0;
  @override
  Future<int?> totalRamMb() async {
    calls++;
    return mb;
  }
}

class _Scripted implements AnswerStrategy {
  _Scripted(this.tokens, {this.failAfter});

  final List<String> tokens;

  /// Throw after emitting this many tokens (0 = before any).
  final int? failAfter;
  int calls = 0;

  @override
  Stream<String> answer({
    required String question,
    required List<RetrievedChunk> chunks,
    List<ChatTurn> history = const [],
  }) async* {
    calls++;
    for (var i = 0; i < tokens.length; i++) {
      if (failAfter == i) throw StateError('engine failed');
      yield tokens[i];
    }
    if (failAfter == tokens.length) throw StateError('engine failed');
  }
}

RetrievedChunk chunk(String text, double score) {
  final now = DateTime(2026, 11, 7);
  return RetrievedChunk(
    chunk: EmbeddingChunk(
      id: text,
      chunkType: 'transaction',
      text: text,
      sourceId: text,
      createdAt: now,
      updatedAt: now,
    ),
    similarity: score,
  );
}

Future<String> run(AnswerStrategy s, [List<RetrievedChunk>? chunks]) =>
    s.answer(question: 'q', chunks: chunks ?? [chunk('fact', 1)]).join();

void main() {
  group('TemplateAnswerStrategy', () {
    test('lists distinct retrieved facts with a lite-mode note', () async {
      final text = await run(const TemplateAnswerStrategy(maxFacts: 2), [
        chunk('₹500 spent on Travel on Jul 24.', .9),
        chunk('₹500 spent on Travel on Jul 24.', .8),
        chunk('Your Food budget of ₹4000 is 98% used.', .7),
        chunk('ignored: beyond maxFacts', .6),
      ]);

      expect(text, contains('• ₹500 spent on Travel on Jul 24.'));
      expect(text, contains('• Your Food budget of ₹4000 is 98% used.'));
      expect(text, isNot(contains('beyond maxFacts')));
      expect(text, contains(TemplateAnswerStrategy.liteNote));
    });

    test('says so when nothing matched', () async {
      expect(
        await run(const TemplateAnswerStrategy(), const []),
        TemplateAnswerStrategy.nothingFound,
      );
    });
  });

  group('AdaptiveAnswerStrategy', () {
    test('uses Gemma on capable devices', () async {
      final primary = _Scripted(['Hello', ' there']);
      final fallback = _Scripted(['lite']);
      final s = AdaptiveAnswerStrategy(
        primary: primary,
        fallback: fallback,
        device: _Ram(6000),
      );

      expect(await run(s), 'Hello there');
      expect(fallback.calls, 0);
    });

    test('skips Gemma below the RAM threshold, checking RAM once', () async {
      final primary = _Scripted(['never']);
      final ram = _Ram(2800);
      final reasons = <Object>[];
      final s = AdaptiveAnswerStrategy(
        primary: primary,
        fallback: _Scripted(['lite']),
        device: ram,
        onFallback: reasons.add,
      );

      expect(await run(s), 'lite');
      expect(await run(s), 'lite');
      expect(primary.calls, 0);
      expect(ram.calls, 1);
      expect(reasons, ['low-ram', 'low-ram']);
    });

    test('unknown RAM tries Gemma', () async {
      final s = AdaptiveAnswerStrategy(
        primary: _Scripted(['ok']),
        fallback: _Scripted(['lite']),
        device: _Ram(null),
      );
      expect(await run(s), 'ok');
    });

    test('falls back when Gemma fails before answering', () async {
      final s = AdaptiveAnswerStrategy(
        primary: _Scripted(['x'], failAfter: 0),
        fallback: _Scripted(['lite']),
        device: _Ram(8000),
      );
      expect(await run(s), 'lite');
    });

    test('surfaces failures after part of the answer was shown', () async {
      final s = AdaptiveAnswerStrategy(
        primary: _Scripted(['partial', 'more'], failAfter: 1),
        fallback: _Scripted(['lite']),
        device: _Ram(8000),
      );
      await expectLater(run(s), throwsStateError);
    });
  });
}
