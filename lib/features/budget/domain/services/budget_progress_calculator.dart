import 'package:equatable/equatable.dart';

import '../../../expense/domain/entities/expense_entity.dart';
import '../entities/budget_entity.dart';
import 'budget_period_window.dart';

enum BudgetPaceStatus {
  /// Spending is in line with (or behind) the period's elapsed share.
  onTrack,

  /// At the current daily rate the budget runs out before the period ends.
  atRisk,

  /// Already at or over the limit.
  exceeded,
}

/// Where one category's budget stands in its current period.
class CategoryBudgetProgress extends Equatable {
  final String categoryId;

  /// Effective limit for this period: the set limit plus [carriedOver].
  final double limit;

  /// Unspent amount rolled over from last period (0 when rollover is off).
  final double carriedOver;
  final BudgetPeriod period;
  final BudgetPeriodWindow window;
  final double spent;
  final int daysElapsed;
  final int daysLeft;
  final BudgetPaceStatus status;

  /// Spend projected for the whole period at the current daily rate.
  final double projectedSpend;

  /// Day the budget runs out at the current rate; set only when [status] is
  /// [BudgetPaceStatus.atRisk].
  final DateTime? projectedRunOutDate;

  const CategoryBudgetProgress({
    required this.categoryId,
    required this.limit,
    this.carriedOver = 0,
    required this.period,
    required this.window,
    required this.spent,
    required this.daysElapsed,
    required this.daysLeft,
    required this.status,
    required this.projectedSpend,
    this.projectedRunOutDate,
  });

  double get remaining => limit - spent;

  double get percentUsed => limit <= 0 ? 0 : spent / limit * 100;

  /// What can still be spent per remaining day (never negative).
  double get dailyAllowance =>
      remaining <= 0 || daysLeft <= 0 ? 0 : remaining / daysLeft;

  @override
  List<Object?> get props => [
    categoryId,
    limit,
    carriedOver,
    period,
    window.start,
    spent,
    daysElapsed,
    daysLeft,
    status,
    projectedSpend,
    projectedRunOutDate,
  ];
}

/// Pure budget math shared by the budget screen, dashboard and alerts.
abstract final class BudgetProgressCalculator {
  /// Pace alerts are suppressed for the first few days of a period, when a
  /// single purchase would otherwise project wildly.
  static const minDaysForPace = 3;

  /// Spending must be at least this many percentage points ahead of the
  /// elapsed share of the period before it counts as at risk.
  static const paceMarginPercent = 10.0;

  static List<CategoryBudgetProgress> compute({
    required List<ExpenseEntity> expenses,
    required Map<String, double> limits,
    required Map<String, BudgetPeriod> periods,
    required DateTime now,
    Map<String, double> carryOver = const {},
  }) {
    final result = <CategoryBudgetProgress>[];

    limits.forEach((categoryId, limit) {
      if (limit <= 0) return;
      final period = periods[categoryId] ?? BudgetPeriod.monthly;
      final window = BudgetPeriodWindow.of(period, now);
      if (window == null) return;

      final spent = spentIn(window, categoryId, expenses);
      final carried = carryOver[categoryId] ?? 0;
      result.add(
        _progress(
          categoryId: categoryId,
          limit: limit + carried,
          carriedOver: carried,
          period: period,
          window: window,
          spent: spent,
          now: now,
        ),
      );
    });

    return result;
  }

  static double spentIn(
    BudgetPeriodWindow window,
    String categoryId,
    List<ExpenseEntity> expenses,
  ) {
    var spent = 0.0;
    for (final e in expenses) {
      if (e.isDeleted || e.categoryId != categoryId) continue;
      if (window.contains(e.date)) spent += e.amount;
    }
    return spent;
  }

  static CategoryBudgetProgress _progress({
    required String categoryId,
    required double limit,
    double carriedOver = 0,
    required BudgetPeriod period,
    required BudgetPeriodWindow window,
    required double spent,
    required DateTime now,
  }) {
    final totalDays = window.totalDays;
    final elapsed = window.daysElapsed(now);
    final left = window.daysLeft(now);
    final dailyRate = spent / elapsed;
    final projected = dailyRate * totalDays;

    var status = BudgetPaceStatus.onTrack;
    DateTime? runOut;

    if (spent >= limit) {
      status = BudgetPaceStatus.exceeded;
    } else {
      final elapsedPercent = elapsed / totalDays * 100;
      final usedPercent = spent / limit * 100;
      final ahead = usedPercent - elapsedPercent >= paceMarginPercent;

      if (elapsed >= minDaysForPace && ahead && projected > limit) {
        status = BudgetPaceStatus.atRisk;
        // After k days cumulative spend is k × rate, so the limit is crossed
        // during day ⌈limit / rate⌉ (1-based); convert to a 0-based offset.
        final dayIndex = ((limit / dailyRate).ceil() - 1).clamp(0, totalDays);
        runOut = DateTime(
          window.start.year,
          window.start.month,
          window.start.day + dayIndex,
        );
      }
    }

    return CategoryBudgetProgress(
      categoryId: categoryId,
      limit: limit,
      carriedOver: carriedOver,
      period: period,
      window: window,
      spent: spent,
      daysElapsed: elapsed,
      daysLeft: left,
      status: status,
      projectedSpend: projected,
      projectedRunOutDate: runOut,
    );
  }
}
