import 'dart:async';

import 'package:expense_flow_app/features/expense/domain/usecases/add_expense_usecase.dart';
import 'package:expense_flow_app/features/recurring/domain/entities/recurring_expense_entity.dart';
import 'package:expense_flow_app/features/recurring/domain/repositories/recurring_expense_repository.dart';
import 'package:expense_flow_app/features/recurring/domain/usecases/generate_due_recurring_expenses_usecase.dart';
import 'package:expense_flow_app/features/recurring/domain/usecases/manage_recurring_expenses_usecases.dart';
import 'package:expense_flow_app/features/recurring/domain/usecases/start_recurring_expense_usecase.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/in_memory_expense_repository.dart';

class _InMemoryRecurringRepository implements RecurringExpenseRepository {
  final Map<String, RecurringExpenseEntity> byId = {};
  final _changes = StreamController<void>.broadcast();

  @override
  Future<void> delete(String id) async {
    byId.remove(id);
    _changes.add(null);
  }

  @override
  Future<List<RecurringExpenseEntity>> getAll() async => byId.values.toList();

  @override
  Future<RecurringExpenseEntity?> getById(String id) async => byId[id];

  @override
  Future<void> save(RecurringExpenseEntity rule) async {
    byId[rule.id] = rule;
    _changes.add(null);
  }

  @override
  Stream<void> watch() => _changes.stream;
}

void main() {
  late InMemoryExpenseRepository expenses;
  late _InMemoryRecurringRepository rules;
  late DateTime now;

  AddExpenseUseCase addExpense() => AddExpenseUseCase(expenses, now: () => now);

  StartRecurringExpenseUseCase start() => StartRecurringExpenseUseCase(
    repository: rules,
    addExpense: addExpense(),
    now: () => now,
    newId: () => 'rule1',
  );

  GenerateDueRecurringExpensesUseCase generate() =>
      GenerateDueRecurringExpensesUseCase(
        repository: rules,
        addExpense: addExpense(),
        now: () => now,
      );

  AddExpenseParams rent(DateTime date) => AddExpenseParams(
    amount: 15000,
    currency: 'INR',
    originalAmount: 15000,
    exchangeRate: 1,
    categoryId: 'bills',
    title: 'Rent',
    merchant: 'Landlord',
    paymentMethod: 'UPI',
    date: date,
  );

  setUp(() {
    expenses = InMemoryExpenseRepository();
    rules = _InMemoryRecurringRepository();
    now = DateTime(2026, 1, 31, 10);
  });

  group('StartRecurringExpenseUseCase', () {
    test('saves the rule and logs the first occurrence', () async {
      final first = await start()(
        firstExpense: rent(now),
        frequency: RecurrenceFrequency.monthly,
      );

      expect(first.id, 'rule1_0');
      expect(first.recurringId, 'rule1');
      expect(first.merchant, 'Landlord');

      final rule = rules.byId['rule1']!;
      expect(rule.generatedCount, 1);
      expect(rule.startDate, now);
      expect(rule.isActive, isTrue);
    });

    test('does not save a rule when the expense is invalid', () async {
      final invalid = AddExpenseParams(
        amount: 0,
        currency: 'INR',
        categoryId: 'bills',
        date: now,
      );

      await expectLater(
        start()(firstExpense: invalid, frequency: RecurrenceFrequency.daily),
        throwsA(isA<Exception>()),
      );
      expect(rules.byId, isEmpty);
      expect(expenses.byId, isEmpty);
    });

    test('rejects an interval below 1', () async {
      expect(
        () => start()(
          firstExpense: rent(now),
          frequency: RecurrenceFrequency.weekly,
          interval: 0,
        ),
        throwsArgumentError,
      );
    });
  });

  group('GenerateDueRecurringExpensesUseCase', () {
    test('creates every missed occurrence with clamped dates', () async {
      await start()(
        firstExpense: rent(now),
        frequency: RecurrenceFrequency.monthly,
      );

      now = DateTime(2026, 4, 30, 12);
      final created = await generate()();

      expect(created, 3);
      expect(
        expenses.byId.keys,
        containsAll(['rule1_1', 'rule1_2', 'rule1_3']),
      );
      expect(expenses.byId['rule1_1']!.date, DateTime(2026, 2, 28, 10));
      expect(expenses.byId['rule1_2']!.date, DateTime(2026, 3, 31, 10));
      expect(expenses.byId['rule1_3']!.date, DateTime(2026, 4, 30, 10));
      expect(rules.byId['rule1']!.generatedCount, 4);
    });

    test('is idempotent across repeated runs', () async {
      await start()(
        firstExpense: rent(now),
        frequency: RecurrenceFrequency.monthly,
      );
      now = DateTime(2026, 3, 31, 12);

      await generate()();
      final secondRun = await generate()();

      expect(secondRun, 0);
      expect(expenses.byId, hasLength(3));
    });

    test(
      'regenerating after a crash overwrites instead of duplicating',
      () async {
        await start()(
          firstExpense: rent(now),
          frequency: RecurrenceFrequency.monthly,
        );
        now = DateTime(2026, 3, 31, 12);
        await generate()();

        // Simulate a crash after the expenses were written but before the
        // rule's progress was saved.
        final rule = rules.byId['rule1']!;
        rules.byId['rule1'] = rule.copyWith(generatedCount: 1);

        await generate()();

        expect(expenses.byId, hasLength(3));
      },
    );

    test('skips paused rules', () async {
      await start()(
        firstExpense: rent(now),
        frequency: RecurrenceFrequency.daily,
      );
      rules.byId['rule1'] = rules.byId['rule1']!.copyWith(isActive: false);

      now = now.add(const Duration(days: 10));

      expect(await generate()(), 0);
    });

    test('stops at endDate and deactivates the rule', () async {
      final startDate = DateTime(2026, 1, 1, 9);
      now = startDate;
      await rules.save(
        RecurringExpenseEntity(
          id: 'gym',
          amount: 500,
          currency: 'INR',
          categoryId: 'health',
          frequency: RecurrenceFrequency.weekly,
          startDate: startDate,
          endDate: DateTime(2026, 1, 20),
          createdAt: startDate,
          updatedAt: startDate,
        ),
      );

      now = DateTime(2026, 3, 1);
      final created = await generate()();

      // Jan 1, 8, 15 are on or before the end date; Jan 22 is not.
      expect(created, 3);
      expect(rules.byId['gym']!.isActive, isFalse);
      expect(rules.byId['gym']!.generatedCount, 3);
    });

    test('caps occurrences per run', () async {
      final startDate = DateTime(2020, 1, 1);
      await rules.save(
        RecurringExpenseEntity(
          id: 'daily',
          amount: 10,
          currency: 'INR',
          categoryId: 'food',
          frequency: RecurrenceFrequency.daily,
          startDate: startDate,
          createdAt: startDate,
          updatedAt: startDate,
        ),
      );

      now = DateTime(2026, 1, 1);
      final created = await generate()();

      expect(created, GenerateDueRecurringExpensesUseCase.maxOccurrencesPerRun);
    });
  });

  group('SetRecurringExpenseActiveUseCase', () {
    test('resuming skips occurrences missed while paused', () async {
      await start()(
        firstExpense: rent(now),
        frequency: RecurrenceFrequency.monthly,
      );
      final setActive = SetRecurringExpenseActiveUseCase(rules, now: () => now);

      await setActive('rule1', active: false);
      expect(rules.byId['rule1']!.isActive, isFalse);

      now = DateTime(2026, 6, 15);
      await setActive('rule1', active: true);

      final resumed = rules.byId['rule1']!;
      expect(resumed.isActive, isTrue);
      // Next due is Jun 30, not a backlog from February.
      expect(resumed.generatedCount, 5);
      expect(await generate()(), 0);
    });
  });

  group('GetRecurringExpensesUseCase', () {
    test('orders active rules first, then by next due date', () async {
      RecurringExpenseEntity rule(String id, int day, {bool active = true}) {
        final date = DateTime(2026, 1, day);
        return RecurringExpenseEntity(
          id: id,
          amount: 1,
          currency: 'INR',
          categoryId: 'food',
          frequency: RecurrenceFrequency.monthly,
          startDate: date,
          isActive: active,
          createdAt: date,
          updatedAt: date,
        );
      }

      await rules.save(rule('paused', 1, active: false));
      await rules.save(rule('late', 20));
      await rules.save(rule('early', 5));

      final ordered = await GetRecurringExpensesUseCase(rules)();

      expect(ordered.map((r) => r.id), ['early', 'late', 'paused']);
    });
  });
}
