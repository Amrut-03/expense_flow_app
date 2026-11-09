import 'dart:async';

import 'package:expense_flow_app/features/budget/domain/entities/budget_entity.dart';
import 'package:expense_flow_app/features/budget/domain/entities/budget_rollover.dart';
import 'package:expense_flow_app/features/budget/domain/repositories/budget_repository.dart';
import 'package:expense_flow_app/features/budget/domain/repositories/budget_rollover_repository.dart';
import 'package:expense_flow_app/features/budget/domain/services/rollover_calculator.dart';
import 'package:expense_flow_app/features/budget/domain/usecases/get_budget_insights_usecase.dart';
import 'package:expense_flow_app/features/budget/domain/usecases/settle_budget_rollover_usecase.dart';
import 'package:expense_flow_app/features/goals/domain/entities/savings_goal.dart';
import 'package:expense_flow_app/features/goals/domain/repositories/savings_goal_repository.dart';
import 'package:expense_flow_app/features/goals/domain/usecases/savings_goal_usecases.dart';
import 'package:expense_flow_app/features/recurring/domain/entities/recurring_expense_entity.dart';
import 'package:expense_flow_app/features/recurring/domain/repositories/recurring_expense_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/expense_factory.dart';
import '../../helpers/in_memory_expense_repository.dart';

class _Budgets implements BudgetRepository {
  Map<String, double> limits = {};
  Map<String, BudgetPeriod> periods = {};
  @override
  Future<Map<String, double>> getLimits() async => limits;
  @override
  Future<Map<String, BudgetPeriod>> getPeriods() async => periods;
  @override
  Future<void> setAll(Map<String, double> l, Map<String, BudgetPeriod> p) async {
    limits = l;
    periods = p;
  }

  @override
  Future<void> setLimits(Map<String, double> l) async => limits = l;
  @override
  Future<void> setPeriods(Map<String, BudgetPeriod> p) async => periods = p;
}

class _Rollover implements BudgetRolloverRepository {
  final Map<String, BudgetRolloverSetting> settings = {};
  final Set<String> settled = {};
  String _key(String c, DateTime s) => '$c-${s.year}-${s.month}';
  @override
  Map<String, BudgetRolloverSetting> getAll() => Map.of(settings);
  @override
  Future<void> set(String c, BudgetRolloverSetting s) async {
    if (s.mode == BudgetRolloverMode.none) {
      settings.remove(c);
    } else {
      settings[c] = s;
    }
  }

  @override
  bool isSettled(String c, DateTime s) => settled.contains(_key(c, s));
  @override
  Future<void> markSettled(String c, DateTime s) async =>
      settled.add(_key(c, s));
}

class _Goals implements SavingsGoalRepository {
  final Map<String, SavingsGoal> byId = {};
  @override
  Future<void> delete(String id) async => byId.remove(id);
  @override
  Future<List<SavingsGoal>> getAll() async => byId.values.toList();
  @override
  Future<SavingsGoal?> getById(String id) async => byId[id];
  @override
  Future<void> save(SavingsGoal goal) async => byId[goal.id] = goal;
  @override
  Stream<void> watch() => const Stream.empty();
}

class _NoRecurring implements RecurringExpenseRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
  @override
  Future<List<RecurringExpenseEntity>> getAll() async => const [];
}

void main() {
  final now = DateTime(2026, 11, 9);
  const carry = BudgetRolloverSetting(mode: BudgetRolloverMode.carryForward);

  group('RolloverCalculator', () {
    test('unspent last month = limit − spent, never negative', () {
      final expenses = [
        expenseOf(amount: 1, date: DateTime(2026, 9, 1)), // tracking since Sep
        expenseOf(amount: 3000, date: DateTime(2026, 10, 5)),
      ];
      double unspent(double limit) => RolloverCalculator.unspentLastPeriod(
        categoryId: 'food',
        limit: limit,
        period: BudgetPeriod.monthly,
        expenses: expenses,
        now: now,
      );
      expect(unspent(5000), 2000);
      expect(unspent(2000), 0);
      expect(unspent(0), 0);
    });

    test('new users do not carry over an untracked month', () {
      final amount = RolloverCalculator.unspentLastPeriod(
        categoryId: 'food',
        limit: 5000,
        period: BudgetPeriod.monthly,
        expenses: [expenseOf(amount: 100, date: DateTime(2026, 11, 2))],
        now: now,
      );
      expect(amount, 0);
    });

    test('carryOver only covers carry-forward categories', () {
      final expenses = [
        expenseOf(amount: 1, date: DateTime(2026, 9, 1)),
        expenseOf(amount: 1000, date: DateTime(2026, 10, 5)),
        expenseOf(
          amount: 500,
          date: DateTime(2026, 10, 6),
          categoryId: 'shopping',
        ),
      ];
      final result = RolloverCalculator.carryOver(
        limits: {'food': 4000, 'shopping': 2000, 'travel': 1000},
        periods: const {},
        settings: {
          'food': carry,
          'shopping': const BudgetRolloverSetting(
            mode: BudgetRolloverMode.toGoal,
            goalId: 'g',
          ),
        },
        expenses: expenses,
        now: now,
      );
      expect(result, {'food': 3000});
    });

    test('quarterly budgets look at the previous quarter', () {
      final window = RolloverCalculator.previousWindow(
        BudgetPeriod.quarterly,
        now,
      )!;
      expect(window.start, DateTime(2026, 7, 1));
    });
  });

  group('GetBudgetInsightsUseCase with rollover', () {
    test('adds carried-over amount to the effective limit', () async {
      final expenses = InMemoryExpenseRepository();
      for (final e in [
        expenseOf(amount: 1, date: DateTime(2026, 9, 1)),
        expenseOf(amount: 1000, date: DateTime(2026, 10, 5)),
        expenseOf(amount: 500, date: DateTime(2026, 11, 3)),
      ]) {
        await expenses.addExpense(e);
      }
      final budgets = _Budgets()..limits = {'food': 4000};
      final rollover = _Rollover()..settings['food'] = carry;

      final insights = await GetBudgetInsightsUseCase(
        expenseRepository: expenses,
        budgetRepository: budgets,
        recurringRepository: _NoRecurring(),
        rolloverRepository: rollover,
        now: () => now,
      )();

      final food = insights.budgetFor('food')!;
      expect(food.carriedOver, 3000);
      expect(food.limit, 7000);
      expect(food.remaining, 6500);
    });
  });

  group('SettleBudgetRolloverUseCase', () {
    late InMemoryExpenseRepository expenses;
    late _Budgets budgets;
    late _Rollover rollover;
    late _Goals goals;
    late SettleBudgetRolloverUseCase settle;

    setUp(() async {
      expenses = InMemoryExpenseRepository();
      await expenses.addExpense(expenseOf(amount: 1, date: DateTime(2026, 9, 1)));
      await expenses.addExpense(
        expenseOf(amount: 1500, date: DateTime(2026, 10, 10)),
      );
      budgets = _Budgets()..limits = {'food': 4000};
      rollover = _Rollover()
        ..settings['food'] = const BudgetRolloverSetting(
          mode: BudgetRolloverMode.toGoal,
          goalId: 'trip',
        );
      goals = _Goals()
        ..byId['trip'] = SavingsGoal(
          id: 'trip',
          name: 'Goa trip',
          emoji: '🏖️',
          target: 20000,
          createdAt: DateTime(2026, 1, 1),
          updatedAt: DateTime(2026, 1, 1),
        );
      settle = SettleBudgetRolloverUseCase(
        rolloverRepository: rollover,
        budgetRepository: budgets,
        expenseRepository: expenses,
        addContribution: AddGoalContributionUseCase(goals, now: () => now),
        now: () => now,
      );
    });

    test('moves last month\'s unspent amount into the goal once', () async {
      final first = await settle();
      expect(first.single.amount, 2500);
      expect(goals.byId['trip']!.saved, 2500);

      final second = await settle();
      expect(second, isEmpty);
      expect(goals.byId['trip']!.saved, 2500, reason: 'idempotent');
    });

    test('turns rollover off when the goal was deleted', () async {
      goals.byId.clear();
      expect(await settle(), isEmpty);
      expect(rollover.settings, isEmpty);
    });

    test('switching to a goal does not sweep the already-closed period',
        () async {
      rollover.settings.clear();
      await SetBudgetRolloverUseCase(
        rolloverRepository: rollover,
        budgetRepository: budgets,
        now: () => now,
      )(
        'food',
        const BudgetRolloverSetting(
          mode: BudgetRolloverMode.toGoal,
          goalId: 'trip',
        ),
      );
      expect(await settle(), isEmpty);
      expect(goals.byId['trip']!.saved, 0);
    });
  });
}
