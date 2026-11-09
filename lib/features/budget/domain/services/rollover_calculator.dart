import '../../../expense/domain/entities/expense_entity.dart';
import '../entities/budget_entity.dart';
import '../entities/budget_rollover.dart';
import 'budget_period_window.dart';
import 'budget_progress_calculator.dart';

abstract final class RolloverCalculator {
  /// The period immediately before the one containing [now].
  static BudgetPeriodWindow? previousWindow(BudgetPeriod period, DateTime now) {
    final current = BudgetPeriodWindow.of(period, now);
    if (current == null) return null;
    final lastDay = DateTime(
      current.start.year,
      current.start.month,
      current.start.day - 1,
    );
    return BudgetPeriodWindow.of(period, lastDay);
  }

  /// Unspent amount of last period: `max(0, limit − spent)`.
  ///
  /// Carries over one period only (no compounding), and uses today's limit
  /// for last period since limit history isn't stored. Returns 0 unless the
  /// user was already logging expenses when last period began; otherwise a
  /// new user would "carry over" a whole untracked budget.
  static double unspentLastPeriod({
    required String categoryId,
    required double limit,
    required BudgetPeriod period,
    required List<ExpenseEntity> expenses,
    required DateTime now,
  }) {
    if (limit <= 0) return 0;
    final window = previousWindow(period, now);
    if (window == null) return 0;
    final tracked = expenses.any(
      (e) => !e.isDeleted && !e.date.isAfter(window.start),
    );
    if (!tracked) return 0;
    final spent = BudgetProgressCalculator.spentIn(
      window,
      categoryId,
      expenses,
    );
    return spent >= limit ? 0 : limit - spent;
  }

  /// Amount added to each carry-forward category's limit this period, for
  /// [BudgetProgressCalculator.compute]'s `carryOver`. Categories set to
  /// [BudgetRolloverMode.toGoal] get nothing here: their unspent money goes
  /// to the goal instead, so counting it twice would inflate the budget.
  static Map<String, double> carryOver({
    required Map<String, double> limits,
    required Map<String, BudgetPeriod> periods,
    required Map<String, BudgetRolloverSetting> settings,
    required List<ExpenseEntity> expenses,
    required DateTime now,
  }) {
    final result = <String, double>{};
    settings.forEach((categoryId, setting) {
      if (setting.mode != BudgetRolloverMode.carryForward) return;
      final amount = unspentLastPeriod(
        categoryId: categoryId,
        limit: limits[categoryId] ?? 0,
        period: periods[categoryId] ?? BudgetPeriod.monthly,
        expenses: expenses,
        now: now,
      );
      if (amount > 0) result[categoryId] = amount;
    });
    return result;
  }
}
