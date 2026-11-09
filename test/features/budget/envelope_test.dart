import 'package:expense_flow_app/features/budget/domain/entities/budget_entity.dart';
import 'package:expense_flow_app/features/budget/domain/entities/envelope.dart';
import 'package:expense_flow_app/features/budget/domain/repositories/envelope_repository.dart';
import 'package:expense_flow_app/features/budget/domain/services/envelope_calculator.dart';
import 'package:expense_flow_app/features/budget/domain/usecases/envelope_usecases.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/expense_factory.dart';

class _MemoryEnvelopes implements EnvelopeRepository {
  EnvelopeSettings settings = const EnvelopeSettings();

  @override
  EnvelopeSettings get() => settings;

  @override
  Future<void> setEnabled(bool enabled, {required DateTime now}) async =>
      settings = EnvelopeSettings(
        enabled: enabled,
        startMonth: DateTime(now.year, now.month),
        incomeByMonth: settings.incomeByMonth,
        moves: settings.moves,
      );

  @override
  Future<void> setIncome(DateTime month, double amount) async =>
      settings = EnvelopeSettings(
        enabled: settings.enabled,
        startMonth: settings.startMonth,
        incomeByMonth: {
          ...settings.incomeByMonth,
          EnvelopeSettings.monthKey(month): amount,
        },
        moves: settings.moves,
      );

  @override
  Future<void> addMove(EnvelopeMove move) async => settings = EnvelopeSettings(
    enabled: settings.enabled,
    startMonth: settings.startMonth,
    incomeByMonth: settings.incomeByMonth,
    moves: [...settings.moves, move],
  );

  @override
  Stream<void> watch() => const Stream.empty();
}

void main() {
  final now = DateTime(2026, 11, 15);
  const limits = {'food': 6000.0, 'shopping': 3000.0};

  test('carries leftovers and overspending into the next month', () {
    final month = EnvelopeCalculator.compute(
      settings: EnvelopeSettings(
        enabled: true,
        startMonth: DateTime(2026, 10),
        incomeByMonth: const {'2026-10': 10000},
      ),
      limits: limits,
      expenses: [
        expenseOf(amount: 4000, date: DateTime(2026, 10, 5)), // food +2000
        expenseOf(
          amount: 3500,
          date: DateTime(2026, 10, 9),
          categoryId: 'shopping',
        ), // shopping −500
        expenseOf(amount: 1000, date: DateTime(2026, 11, 2)),
      ],
      now: now,
    );
    final food = month.byCategory('food')!;
    final shopping = month.byCategory('shopping')!;
    expect(food.carried, 2000);
    expect(food.available, 6000 + 2000 - 1000);
    expect(shopping.carried, -500);
    expect(shopping.available, 2500);
    // Income carries forward from October.
    expect(month.income, 10000);
    expect(month.toBeAssigned, 1000);
  });

  test('moves shift money within the month and net to zero', () {
    final month = EnvelopeCalculator.compute(
      settings: EnvelopeSettings(
        enabled: true,
        startMonth: DateTime(2026, 11),
        moves: [
          EnvelopeMove(
            month: DateTime(2026, 11),
            fromCategoryId: 'food',
            toCategoryId: 'shopping',
            amount: 700,
          ),
          // Last month's move doesn't apply.
          EnvelopeMove(
            month: DateTime(2026, 10),
            fromCategoryId: 'food',
            toCategoryId: 'shopping',
            amount: 9999,
          ),
        ],
      ),
      limits: limits,
      expenses: [
        expenseOf(
          amount: 3700,
          date: DateTime(2026, 11, 3),
          categoryId: 'shopping',
        ),
      ],
      now: now,
    );
    expect(month.byCategory('shopping')!.available, 0);
    expect(month.byCategory('food')!.available, 5300);
    expect(month.overspent, isEmpty);
    expect(month.toBeAssigned, isNull);
  });

  test('adjustments feed budget maths only while enabled, monthly only',
      () async {
    final repo = _MemoryEnvelopes();
    final adjustments = EnvelopeAdjustments(repo);
    Map<String, double>? run() => adjustments.compute(
      limits: {...limits, 'travel': 50000},
      periods: {'travel': BudgetPeriod.yearly},
      expenses: [expenseOf(amount: 1000, date: DateTime(2026, 10, 3))],
      now: now,
    );
    expect(run(), isNull);

    await repo.setEnabled(true, now: DateTime(2026, 10, 1));
    final adj = run()!;
    expect(adj.keys, unorderedEquals(['food', 'shopping']));
    expect(adj['food'], 5000); // 6000 − 1000 carried from October
  });

  test('move validation', () async {
    final repo = _MemoryEnvelopes();
    final move = MoveEnvelopeMoneyUseCase(repo, now: () => now);
    expect(
      await move(from: 'food', to: 'food', amount: 10),
      EnvelopeMoveError.sameEnvelope,
    );
    expect(
      await move(from: 'food', to: 'shopping', amount: 0),
      EnvelopeMoveError.amount,
    );
    expect(await move(from: 'food', to: 'shopping', amount: 10.004), isNull);
    expect(repo.settings.moves.single.amount, 10);
    expect(repo.settings.moves.single.month, DateTime(2026, 11));
  });
}
