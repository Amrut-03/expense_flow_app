import 'package:equatable/equatable.dart';

import '../../../expense/domain/repositories/expense_repository.dart';
import '../../../recurring/domain/repositories/recurring_expense_repository.dart';
import '../../../recurring/domain/services/recurrence_calculator.dart';
import '../repositories/budget_repository.dart';
import '../repositories/budget_rollover_repository.dart';
import '../services/budget_expense_filter.dart';
import '../usecases/envelope_usecases.dart';
import '../services/budget_progress_calculator.dart';
import '../services/rollover_calculator.dart';
import '../services/safe_to_spend_calculator.dart';

class BudgetInsights extends Equatable {
  final List<CategoryBudgetProgress> budgets;
  final SafeToSpend safeToSpend;

  /// Total spent in the current calendar month across all categories.
  final double spentThisMonth;

  /// Spend per category in the current calendar month.
  final Map<String, double> spentThisMonthByCategory;

  /// Recurring charges due before the longest budget period ends.
  final List<UpcomingCharge> upcoming;

  const BudgetInsights({
    required this.budgets,
    required this.safeToSpend,
    required this.spentThisMonth,
    required this.spentThisMonthByCategory,
    this.upcoming = const [],
  });

  static const empty = BudgetInsights(
    budgets: [],
    safeToSpend: SafeToSpend.none,
    spentThisMonth: 0,
    spentThisMonthByCategory: {},
  );

  /// Upcoming charges for [budget]'s category inside its current period.
  double billsFor(CategoryBudgetProgress budget, DateTime now) => upcoming
      .where(
        (c) =>
            c.categoryId == budget.categoryId &&
            c.date.isAfter(now) &&
            budget.window.contains(c.date),
      )
      .fold(0, (sum, c) => sum + c.amount);

  CategoryBudgetProgress? budgetFor(String categoryId) {
    for (final b in budgets) {
      if (b.categoryId == categoryId) return b;
    }
    return null;
  }

  @override
  List<Object?> get props => [
    budgets,
    safeToSpend,
    spentThisMonth,
    spentThisMonthByCategory,
    upcoming,
  ];
}

/// Assembles budget progress, pace and safe-to-spend from the repositories.
class GetBudgetInsightsUseCase {
  GetBudgetInsightsUseCase({
    required this.expenseRepository,
    required this.budgetRepository,
    required this.recurringRepository,
    this.rolloverRepository,
    this.budgetFilter,
    this.envelopes,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final ExpenseRepository expenseRepository;
  final BudgetRepository budgetRepository;
  final RecurringExpenseRepository recurringRepository;

  /// When set, carry-forward categories get last period's unspent amount
  /// added to their limit.
  final BudgetRolloverRepository? rolloverRepository;

  /// Excludes e.g. trip spending that has its own budget. Month totals
  /// still include everything.
  final BudgetExpenseFilter? budgetFilter;

  /// In envelope mode, carry + moves replace rollover settings.
  final EnvelopeAdjustments? envelopes;
  final DateTime Function() _now;

  Future<BudgetInsights> call() async {
    final now = _now();
    final expenses = (await expenseRepository.getExpenses())
        .where((e) => !e.isDeleted)
        .toList();

    final limits = await budgetRepository.getLimits();
    final periods = await budgetRepository.getPeriods();
    final rollover = rolloverRepository;
    final budgetExpenses = budgetFilter?.forBudgets(expenses) ?? expenses;
    final budgets = BudgetProgressCalculator.compute(
      expenses: budgetExpenses,
      limits: limits,
      periods: periods,
      now: now,
      carryOver:
          envelopes?.compute(
            limits: limits,
            periods: periods,
            expenses: budgetExpenses,
            now: now,
          ) ??
          (rollover == null
              ? const {}
              : RolloverCalculator.carryOver(
                  limits: limits,
                  periods: periods,
                  settings: rollover.getAll(),
                  expenses: budgetExpenses,
                  now: now,
                )),
    );

    final horizon = budgets.fold<DateTime>(
      now,
      (latest, b) => b.window.end.isAfter(latest) ? b.window.end : latest,
    );

    final upcoming = await _upcomingCharges(now, horizon);
    final safe = SafeToSpendCalculator.compute(
      budgets: budgets,
      upcoming: upcoming,
      now: now,
    );

    final monthStart = DateTime(now.year, now.month);
    final monthEnd = DateTime(now.year, now.month + 1);
    final byCategory = <String, double>{};
    var monthTotal = 0.0;
    for (final e in expenses) {
      if (e.date.isBefore(monthStart) || !e.date.isBefore(monthEnd)) continue;
      monthTotal += e.amount;
      byCategory.update(
        e.categoryId,
        (v) => v + e.amount,
        ifAbsent: () => e.amount,
      );
    }

    return BudgetInsights(
      budgets: budgets,
      safeToSpend: safe,
      spentThisMonth: monthTotal,
      spentThisMonthByCategory: byCategory,
      upcoming: upcoming,
    );
  }

  Future<List<UpcomingCharge>> _upcomingCharges(
    DateTime now,
    DateTime horizon,
  ) async {
    final charges = <UpcomingCharge>[];

    for (final rule in await recurringRepository.getAll()) {
      if (!rule.isActive) continue;

      for (var i = rule.generatedCount; ; i++) {
        final date = RecurrenceCalculator.occurrenceAt(
          start: rule.startDate,
          frequency: rule.frequency,
          interval: rule.interval,
          index: i,
        );
        final end = rule.endDate;
        if (!date.isBefore(horizon) || (end != null && date.isAfter(end))) {
          break;
        }
        charges.add(
          UpcomingCharge(
            categoryId: rule.categoryId,
            amount: rule.amount,
            date: date,
          ),
        );
      }
    }

    return charges;
  }
}
