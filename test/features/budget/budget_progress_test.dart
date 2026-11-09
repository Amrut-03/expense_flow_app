import 'package:expense_flow_app/features/budget/domain/entities/budget_entity.dart';
import 'package:expense_flow_app/features/budget/domain/services/budget_period_window.dart';
import 'package:expense_flow_app/features/budget/domain/services/budget_progress_calculator.dart';
import 'package:expense_flow_app/features/budget/domain/services/safe_to_spend_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/expense_factory.dart';

void main() {
  group('BudgetPeriodWindow', () {
    test('monthly, quarterly and yearly windows', () {
      final now = DateTime(2026, 11, 7, 15);
      final m = BudgetPeriodWindow.of(BudgetPeriod.monthly, now)!;
      final q = BudgetPeriodWindow.of(BudgetPeriod.quarterly, now)!;
      final y = BudgetPeriodWindow.of(BudgetPeriod.yearly, now)!;

      expect([m.start, m.end], [DateTime(2026, 11), DateTime(2026, 12)]);
      expect([q.start, q.end], [DateTime(2026, 10), DateTime(2027, 1)]);
      expect([y.start, y.end], [DateTime(2026), DateTime(2027)]);
      expect(BudgetPeriodWindow.of(BudgetPeriod.noLimit, now), isNull);
    });

    test('day counting includes today on both sides', () {
      final w = BudgetPeriodWindow.of(
        BudgetPeriod.monthly,
        DateTime(2026, 11, 1),
      )!;
      expect(w.totalDays, 30);
      expect(w.daysElapsed(DateTime(2026, 11, 1, 23)), 1);
      expect(w.daysLeft(DateTime(2026, 11, 1)), 30);
      expect(w.daysLeft(DateTime(2026, 11, 30, 20)), 1);
    });
  });

  group('BudgetProgressCalculator', () {
    List<CategoryBudgetProgress> compute(
      List<double> amounts,
      DateTime now, {
      double limit = 3000,
      BudgetPeriod period = BudgetPeriod.monthly,
      DateTime? spendDate,
    }) {
      return BudgetProgressCalculator.compute(
        expenses: [
          for (final a in amounts)
            expenseOf(amount: a, date: spendDate ?? DateTime(2026, 11, 2)),
          // Outside the period: must be ignored.
          expenseOf(amount: 9999, date: DateTime(2026, 10, 31)),
          // Other category: must be ignored.
          expenseOf(
            amount: 9999,
            date: DateTime(2026, 11, 2),
            categoryId: 'bills',
          ),
          // Deleted: must be ignored.
          expenseOf(amount: 9999, date: DateTime(2026, 11, 2), isDeleted: true),
        ],
        limits: {'food': limit},
        periods: {'food': period},
        now: now,
      );
    }

    test('counts only this period, this category, non-deleted', () {
      final p = compute([500, 250], DateTime(2026, 11, 15)).single;
      expect(p.spent, 750);
      expect(p.remaining, 2250);
    });

    test('on track when spending is in line with the month', () {
      // Day 15 of 30, 40% used.
      final p = compute([1200], DateTime(2026, 11, 15)).single;
      expect(p.status, BudgetPaceStatus.onTrack);
      expect(p.dailyAllowance, closeTo(1800 / 16, 1e-9));
    });

    test('at risk when well ahead of schedule, with run-out date', () {
      // Day 10 of 30: 2000 spent = 200/day, crosses 3000 during day 15.
      final p = compute([2000], DateTime(2026, 11, 10)).single;
      expect(p.status, BudgetPaceStatus.atRisk);
      expect(p.projectedSpend, closeTo(6000, 1e-9));
      expect(p.projectedRunOutDate, DateTime(2026, 11, 15));
    });

    test('no pace alarm in the first days of a period', () {
      // A big purchase on day 2 would project wildly.
      final p = compute(
        [2500],
        DateTime(2026, 11, 2),
        spendDate: DateTime(2026, 11, 1),
      ).single;
      expect(p.status, BudgetPaceStatus.onTrack);
    });

    test('exceeded at or over the limit', () {
      final p = compute([3000], DateTime(2026, 11, 20)).single;
      expect(p.status, BudgetPaceStatus.exceeded);
      expect(p.dailyAllowance, 0);
    });

    test('quarterly budget includes earlier months of the quarter', () {
      final p = BudgetProgressCalculator.compute(
        expenses: [
          expenseOf(amount: 1000, date: DateTime(2026, 10, 5)),
          expenseOf(amount: 500, date: DateTime(2026, 11, 5)),
        ],
        limits: {'food': 9000},
        periods: {'food': BudgetPeriod.quarterly},
        now: DateTime(2026, 11, 7),
      ).single;
      expect(p.spent, 1500);
    });

    test('skips zero limits and noLimit periods', () {
      final result = BudgetProgressCalculator.compute(
        expenses: const [],
        limits: {'food': 0, 'bills': 500},
        periods: {'bills': BudgetPeriod.noLimit},
        now: DateTime(2026, 11, 7),
      );
      expect(result, isEmpty);
    });
  });

  group('SafeToSpendCalculator', () {
    final now = DateTime(2026, 11, 21, 9); // 10 days left incl. today
    List<CategoryBudgetProgress> budgets(Map<String, (double, double)> m) {
      return BudgetProgressCalculator.compute(
        expenses: [
          for (final e in m.entries)
            expenseOf(
              amount: e.value.$2,
              date: DateTime(2026, 11, 3),
              categoryId: e.key,
            ),
        ],
        limits: {for (final e in m.entries) e.key: e.value.$1},
        periods: const {},
        now: now,
      );
    }

    test('sums each budget\'s daily allowance', () {
      final safe = SafeToSpendCalculator.compute(
        budgets: budgets({'food': (6000, 4000), 'transport': (2000, 1000)}),
        upcoming: const [],
        now: now,
      );
      expect(safe.hasBudgets, isTrue);
      expect(safe.today, closeTo(200 + 100, 1e-9));
    });

    test('sets aside upcoming recurring bills inside the period', () {
      final safe = SafeToSpendCalculator.compute(
        budgets: budgets({'bills': (20000, 0)}),
        upcoming: [
          UpcomingCharge(
            categoryId: 'bills',
            amount: 15000,
            date: DateTime(2026, 11, 25),
          ),
          // Next month: outside this budget period.
          UpcomingCharge(
            categoryId: 'bills',
            amount: 15000,
            date: DateTime(2026, 12, 25),
          ),
          // Already past: not upcoming.
          UpcomingCharge(
            categoryId: 'bills',
            amount: 999,
            date: DateTime(2026, 11, 20),
          ),
        ],
        now: now,
      );
      expect(safe.reservedForBills, 15000);
      expect(safe.today, closeTo(5000 / 10, 1e-9));
    });

    test('an over-budget category contributes nothing and is counted', () {
      final safe = SafeToSpendCalculator.compute(
        budgets: budgets({'food': (1000, 1500), 'transport': (2000, 1000)}),
        upcoming: const [],
        now: now,
      );
      expect(safe.overBudgetCount, 1);
      expect(safe.today, closeTo(100, 1e-9));
    });

    test('no budgets means nothing to compute', () {
      final safe = SafeToSpendCalculator.compute(
        budgets: const [],
        upcoming: const [],
        now: now,
      );
      expect(safe.hasBudgets, isFalse);
    });
  });
}
