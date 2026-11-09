import '../services/budget_expense_filter.dart';
import '../../../expense/domain/repositories/expense_repository.dart';
import '../../../goals/domain/usecases/savings_goal_usecases.dart';
import '../entities/budget_entity.dart';
import '../entities/budget_rollover.dart';
import '../repositories/budget_repository.dart';
import '../repositories/budget_rollover_repository.dart';
import '../services/rollover_calculator.dart';

/// One unspent-budget transfer made into a savings goal.
class RolloverTransfer {
  final String categoryId;
  final String goalId;
  final double amount;

  const RolloverTransfer({
    required this.categoryId,
    required this.goalId,
    required this.amount,
  });
}

/// Moves last period's unspent budget into the chosen savings goal for
/// every category set to [BudgetRolloverMode.toGoal]. Runs at launch and is
/// idempotent: each (category, period) is settled at most once.
class SettleBudgetRolloverUseCase {
  SettleBudgetRolloverUseCase({
    required this.rolloverRepository,
    required this.budgetRepository,
    required this.expenseRepository,
    required this.addContribution,
    this.budgetFilter,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final BudgetRolloverRepository rolloverRepository;
  final BudgetRepository budgetRepository;
  final ExpenseRepository expenseRepository;
  final AddGoalContributionUseCase addContribution;
  final BudgetExpenseFilter? budgetFilter;
  final DateTime Function() _now;

  Future<List<RolloverTransfer>> call() async {
    final settings = rolloverRepository.getAll();
    final toGoal = {
      for (final e in settings.entries)
        if (e.value.mode == BudgetRolloverMode.toGoal && e.value.goalId != null)
          e.key: e.value.goalId!,
    };
    if (toGoal.isEmpty) return const [];

    final now = _now();
    final limits = await budgetRepository.getLimits();
    final periods = await budgetRepository.getPeriods();
    final all = (await expenseRepository.getExpenses())
        .where((e) => !e.isDeleted)
        .toList();
    final expenses = budgetFilter?.forBudgets(all) ?? all;

    final transfers = <RolloverTransfer>[];
    for (final MapEntry(key: categoryId, value: goalId) in toGoal.entries) {
      final period = periods[categoryId] ?? BudgetPeriod.monthly;
      final window = RolloverCalculator.previousWindow(period, now);
      if (window == null) continue;
      if (rolloverRepository.isSettled(categoryId, window.start)) continue;

      final amount = RolloverCalculator.unspentLastPeriod(
        categoryId: categoryId,
        limit: limits[categoryId] ?? 0,
        period: period,
        expenses: expenses,
        now: now,
      );

      if (amount > 0) {
        try {
          await addContribution(
            goalId,
            double.parse(amount.toStringAsFixed(2)),
          );
        } on GoalValidationException {
          // Goal was deleted: stop routing money to it.
          await rolloverRepository.set(categoryId, BudgetRolloverSetting.off);
          continue;
        }
        transfers.add(
          RolloverTransfer(
            categoryId: categoryId,
            goalId: goalId,
            amount: amount,
          ),
        );
      }
      // Mark settled even at 0 so a later edit to old expenses can't
      // trigger a surprise transfer for a closed period.
      await rolloverRepository.markSettled(categoryId, window.start);
    }
    return transfers;
  }
}

/// Changes a category's rollover mode.
///
/// Switching to [BudgetRolloverMode.toGoal] only affects periods that end
/// from now on: the period that already closed is marked settled, so turning
/// the option on never sweeps last month's money into a goal by surprise.
class SetBudgetRolloverUseCase {
  SetBudgetRolloverUseCase({
    required this.rolloverRepository,
    required this.budgetRepository,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final BudgetRolloverRepository rolloverRepository;
  final BudgetRepository budgetRepository;
  final DateTime Function() _now;

  Future<void> call(String categoryId, BudgetRolloverSetting setting) async {
    if (setting.mode == BudgetRolloverMode.toGoal) {
      final period =
          (await budgetRepository.getPeriods())[categoryId] ??
          BudgetPeriod.monthly;
      final window = RolloverCalculator.previousWindow(period, _now());
      if (window != null) {
        await rolloverRepository.markSettled(categoryId, window.start);
      }
    }
    await rolloverRepository.set(categoryId, setting);
  }
}
