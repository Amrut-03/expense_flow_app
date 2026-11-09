import 'package:expense_flow_app/core/constants/note_limits.dart';
import 'package:expense_flow_app/features/expense/domain/entities/expense_entity.dart';
import 'package:expense_flow_app/features/expense/domain/repositories/expense_repository.dart';
import 'package:expense_flow_app/features/expense/domain/usecases/add_expense_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockExpenseRepository extends Mock implements ExpenseRepository {}

class _FakeExpense extends Fake implements ExpenseEntity {}

void main() {
  late _MockExpenseRepository repository;
  late AddExpenseUseCase useCase;
  final now = DateTime(2026, 11, 7, 10, 30);

  setUpAll(() => registerFallbackValue(_FakeExpense()));

  setUp(() {
    repository = _MockExpenseRepository();
    when(() => repository.addExpense(any())).thenAnswer((_) async {});
    useCase = AddExpenseUseCase(
      repository,
      now: () => now,
      newId: () => 'generated-id',
    );
  });

  AddExpenseParams params({
    String? id,
    double amount = 250,
    String categoryId = 'food',
    String? note,
    String? title = 'Lunch',
    String? merchant,
    double? originalAmount,
    double? exchangeRate,
    DateTime? date,
  }) {
    return AddExpenseParams(
      id: id,
      amount: amount,
      currency: 'INR',
      categoryId: categoryId,
      note: note,
      title: title,
      merchant: merchant,
      originalAmount: originalAmount,
      exchangeRate: exchangeRate,
      paymentMethod: 'UPI',
      date: date ?? now,
    );
  }

  group('AddExpenseUseCase', () {
    test('persists a pending, versioned expense with all fields', () async {
      final result = await useCase(
        params(
          merchant: ' Swiggy ',
          originalAmount: 3,
          exchangeRate: 83.33,
          amount: 249.99,
        ),
      );

      expect(result.id, 'generated-id');
      expect(result.amount, 249.99);
      expect(result.merchant, 'Swiggy');
      expect(result.originalAmount, 3);
      expect(result.exchangeRate, 83.33);
      expect(result.syncStatus, SyncStatus.pending);
      expect(result.version, 1);
      expect(result.createdAt, now);
      expect(result.updatedAt, now);
      verify(() => repository.addExpense(result)).called(1);
    });

    test('uses a caller-supplied id when given', () async {
      final result = await useCase(params(id: 'rule_3'));

      expect(result.id, 'rule_3');
    });

    test('normalises blank optional text to null', () async {
      final result = await useCase(
        params(note: '   ', title: '  ', merchant: ''),
      );

      expect(result.note, isNull);
      expect(result.title, isNull);
      expect(result.merchant, isNull);
    });

    final invalid = <String, AddExpenseParams Function()>{
      'zero amount': () => params(amount: 0),
      'negative amount': () => params(amount: -5),
      'more than two decimals': () => params(amount: 10.123),
      'amount above limit': () => params(amount: 1000000.01),
      'blank category': () => params(categoryId: '  '),
      'note too long': () => params(note: 'x' * (NoteLimits.maxLength + 1)),
      'title too long': () =>
          params(title: 'x' * (NoteLimits.titleMaxLength + 1)),
      'merchant too long': () =>
          params(merchant: 'x' * (NoteLimits.merchantMaxLength + 1)),
      'non-positive original amount': () => params(originalAmount: 0),
      'non-positive exchange rate': () => params(exchangeRate: 0),
      'date older than ten years': () =>
          params(date: now.subtract(const Duration(days: 365 * 10 + 1))),
    };

    invalid.forEach((name, build) {
      test('rejects $name without saving', () async {
        await expectLater(useCase(build()), throwsA(isA<Exception>()));
        verifyNever(() => repository.addExpense(any()));
      });
    });

    test('accepts boundary values', () async {
      await useCase(params(amount: 1000000));
      await useCase(params(amount: 0.01));
      await useCase(params(merchant: 'x' * NoteLimits.merchantMaxLength));

      verify(() => repository.addExpense(any())).called(3);
    });
  });
}
