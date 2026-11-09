import 'package:equatable/equatable.dart';

import 'budget_progress_calculator.dart';

/// A known future charge (from a recurring rule) that will eat into a budget.
class UpcomingCharge extends Equatable {
  final String categoryId;
  final double amount;
  final DateTime date;

  const UpcomingCharge({
    required this.categoryId,
    required this.amount,
    required this.date,
  });

  @override
  List<Object?> get props => [categoryId, amount, date];
}

class SafeToSpend extends Equatable {
  /// Total that can be spent today across all budgeted categories.
  final double today;

  /// Upcoming recurring charges already set aside within budget periods.
  final double reservedForBills;

  /// Number of budgeted categories that are already over their limit.
  final int overBudgetCount;

  /// False when the user has no active budgets (nothing to compute from).
  final bool hasBudgets;

  const SafeToSpend({
    required this.today,
    required this.reservedForBills,
    required this.overBudgetCount,
    required this.hasBudgets,
  });

  static const none = SafeToSpend(
    today: 0,
    reservedForBills: 0,
    overBudgetCount: 0,
    hasBudgets: false,
  );

  @override
  List<Object?> get props => [
    today,
    reservedForBills,
    overBudgetCount,
    hasBudgets,
  ];
}

abstract final class SafeToSpendCalculator {
  /// Sums each budget's daily allowance after setting aside upcoming
  /// recurring charges that fall inside that budget's period:
  ///
  /// `allowance = max(0, limit − spent − upcoming) / daysLeft`
  ///
  /// Each budget contributes a per-day figure, so budgets with different
  /// periods (monthly, quarterly, yearly) combine meaningfully.
  static SafeToSpend compute({
    required List<CategoryBudgetProgress> budgets,
    required List<UpcomingCharge> upcoming,
    required DateTime now,
  }) {
    if (budgets.isEmpty) return SafeToSpend.none;

    var today = 0.0;
    var reserved = 0.0;
    var over = 0;

    for (final budget in budgets) {
      final bills = upcoming
          .where(
            (c) =>
                c.categoryId == budget.categoryId &&
                c.date.isAfter(now) &&
                budget.window.contains(c.date),
          )
          .fold<double>(0, (sum, c) => sum + c.amount);

      if (budget.spent >= budget.limit) over++;

      final available = budget.limit - budget.spent - bills;
      reserved += bills;
      if (available > 0 && budget.daysLeft > 0) {
        today += available / budget.daysLeft;
      }
    }

    return SafeToSpend(
      today: today,
      reservedForBills: reserved,
      overBudgetCount: over,
      hasBudgets: true,
    );
  }
}
