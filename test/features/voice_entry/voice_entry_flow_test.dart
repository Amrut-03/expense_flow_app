import 'package:expense_flow_app/features/voice_entry/domain/entities/voice_expense_draft.dart';
import 'package:expense_flow_app/features/voice_entry/domain/services/speech_recognizer.dart';
import 'package:expense_flow_app/features/voice_entry/domain/usecases/parse_voice_expense_usecase.dart';
import 'package:expense_flow_app/features/voice_entry/presentation/cubit/voice_entry_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/in_memory_expense_repository.dart';

const _ids = ['food', 'transport', 'bills', 'other'];

class _FakeRefiner implements VoiceExpenseRefiner {
  _FakeRefiner(this.output, {this.available = true});
  final String output;
  final bool available;
  int calls = 0;
  @override
  Future<bool> isAvailable() async => available;
  @override
  Future<String> extract(String t, {required List<String> categories}) async {
    calls++;
    return output;
  }
}

class _FakeRecognizer implements SpeechRecognizer {
  _FakeRecognizer(this.results);
  final List<({String? transcript, SpeechFailure? failure})> results;
  SpeechFailure? initFailure;
  final List<bool> onDeviceCalls = [];
  @override
  Future<SpeechFailure?> initialize() async => initFailure;
  @override
  Future<({String? transcript, SpeechFailure? failure})> listen({
    required String localeId,
    required bool onDevice,
    required void Function(String text) onPartial,
  }) async {
    onDeviceCalls.add(onDevice);
    final r = results.removeAt(0);
    if (r.transcript != null) onPartial(r.transcript!);
    return r;
  }

  @override
  Future<void> stop() async {}
  @override
  Future<void> cancel() async {}
}

void main() {
  group('ParseVoiceExpenseUseCase.merge', () {
    const base = VoiceExpenseDraft(transcript: 'kal raat ka khana 340');

    test('fills gaps with validated model fields', () {
      final merged = ParseVoiceExpenseUseCase.merge(
        base.copyWith(amount: 340),
        'Sure! {"amount": 340, "title": "Dinner", "merchant": null, '
        '"category": "food", "payment": "UPI"}',
        categoryIds: _ids,
      );
      expect(merged.categoryId, 'food');
      expect(merged.title, 'Dinner');
      expect(merged.paymentMethod, 'UPI');
      expect(merged.refinedByModel, isTrue);
    });

    test('rejects invented amounts, merchants and unknown values', () {
      final merged = ParseVoiceExpenseUseCase.merge(
        base,
        '{"amount": 3400, "merchant": "Zomato", "category": "luxury", '
        '"payment": "Crypto"}',
        categoryIds: _ids,
      );
      expect(merged.amount, isNull);
      expect(merged.merchant, isNull);
      expect(merged.categoryId, isNull);
      expect(merged.paymentMethod, isNull);
      expect(merged.refinedByModel, isFalse);
    });

    test('rule-based values win over the model', () {
      final merged = ParseVoiceExpenseUseCase.merge(
        base.copyWith(amount: 340, categoryId: 'other'),
        '{"amount": 340, "category": "food"}',
        categoryIds: _ids,
      );
      expect(merged.categoryId, 'other');
    });

    test('garbage output leaves the draft untouched', () {
      expect(
        ParseVoiceExpenseUseCase.merge(base, 'no json here', categoryIds: _ids),
        base,
      );
    });
  });

  group('ParseVoiceExpenseUseCase', () {
    test('skips the model when the rules already got everything', () async {
      final refiner = _FakeRefiner('{}');
      final draft = await ParseVoiceExpenseUseCase(
        expenseRepository: InMemoryExpenseRepository(),
        refiner: refiner,
      )('चहा 20 रुपये', categoryIds: _ids);
      expect(draft.amount, 20);
      expect(refiner.calls, 0);
    });

    test('asks the model when the category is missing', () async {
      final refiner = _FakeRefiner('{"category": "food", "title": "Dinner"}');
      final draft = await ParseVoiceExpenseUseCase(
        expenseRepository: InMemoryExpenseRepository(),
        refiner: refiner,
      )('kal raat 340 rupees', categoryIds: _ids);
      expect(refiner.calls, 1);
      expect(draft.amount, 340);
      expect(draft.categoryId, 'food');
    });

    test('unavailable model falls back silently', () async {
      final refiner = _FakeRefiner('{"category":"food"}', available: false);
      final draft = await ParseVoiceExpenseUseCase(
        expenseRepository: InMemoryExpenseRepository(),
        refiner: refiner,
      )('kal raat 340', categoryIds: _ids);
      expect(refiner.calls, 0);
      expect(draft.categoryId, isNull);
      expect(draft.amount, 340);
    });
  });

  group('VoiceEntryCubit', () {
    VoiceEntryCubit cubit(_FakeRecognizer r) => VoiceEntryCubit(
      recognizer: r,
      parse: ParseVoiceExpenseUseCase(
        expenseRepository: InMemoryExpenseRepository(),
      ),
      categoryIds: _ids,
      localeId: 'mr-IN',
    );

    test('listens on-device and produces a draft', () async {
      final r = _FakeRecognizer([(transcript: 'चहा 20 रुपये', failure: null)]);
      final c = cubit(r);
      await c.start();
      expect(c.state.phase, VoicePhase.done);
      expect(c.state.draft!.amount, 20);
      expect(r.onDeviceCalls, [true]);
      await c.close();
    });

    test('offline pack missing → user can opt into online', () async {
      final r = _FakeRecognizer([
        (transcript: null, failure: SpeechFailure.languageUnavailableOffline),
        (transcript: 'petrol 500', failure: null),
      ]);
      final c = cubit(r);
      await c.start();
      expect(c.state.phase, VoicePhase.failed);
      expect(c.state.failure, SpeechFailure.languageUnavailableOffline);
      await c.retryOnline();
      expect(r.onDeviceCalls, [true, false]);
      expect(c.state.draft!.categoryId, 'transport');
      await c.close();
    });

    test('permission denied and nothing understood', () async {
      final denied = _FakeRecognizer([])
        ..initFailure = SpeechFailure.permissionDenied;
      final c1 = cubit(denied);
      await c1.start();
      expect(c1.state.failure, SpeechFailure.permissionDenied);

      final c2 = cubit(_FakeRecognizer([(transcript: 'hmm', failure: null)]));
      await c2.start();
      expect(c2.state.phase, VoicePhase.done);
      expect(c2.state.draft!.title, 'Hmm');

      final c3 = cubit(_FakeRecognizer([(transcript: '  ', failure: null)]));
      await c3.start();
      expect(c3.state.failure, SpeechFailure.noMatch);
      await Future.wait([c1.close(), c2.close(), c3.close()]);
    });
  });
}
