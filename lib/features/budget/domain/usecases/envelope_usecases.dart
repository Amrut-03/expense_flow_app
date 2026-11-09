import '../../../expense/domain/entities/expense_entity.dart';
import '../../../expense/domain/repositories/expense_repository.dart';
import '../entities/budget_entity.dart';
import '../entities/envelope.dart';
import '../repositories/budget_repository.dart';
import '../repositories/envelope_repository.dart';
import '../services/budget_expense_filter.dart';
import '../services/envelope_calculator.dart';

/// Envelope adjustments (carry + moves) to add to budget limits while
/// envelope mode is on; `null` when it's off. Used by budget progress,
/// alerts and safe-to-spend so every screen agrees with the envelopes.
class EnvelopeAdjustments {
  EnvelopeAdjustments(this.repository);

  final EnvelopeRepository repository;

  bool get enabled => repository.get().enabled;

  Map<String, double>? compute({
    required Map<String, double> limits,
    required Map<String, BudgetPeriod> periods,
    required List<ExpenseEntity> expenses,
    required DateTime now,
  }) {
    final settings = repository.get();
    if (!settings.enabled) return null;
    final month = EnvelopeCalculator.compute(
      settings: settings,
      limits: monthlyOnly(limits, periods),
      expenses: expenses,
      now: now,
    );
    return {for (final e in month.envelopes) e.categoryId: e.adjustment};
  }

  /// Envelopes are monthly; weekly/yearly budgets stay outside them.
  static Map<String, double> monthlyOnly(
    Map<String, double> limits,
    Map<String, BudgetPeriod> periods,
  ) => {
    for (final e in limits.entries)
      if ((periods[e.key] ?? BudgetPeriod.monthly) == BudgetPeriod.monthly)
        e.key: e.value,
  };
}

class GetEnvelopeMonthUseCase {
  GetEnvelopeMonthUseCase({
    required this.repository,
    required this.budgetRepository,
    required this.expenseRepository,
    this.budgetFilter,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final EnvelopeRepository repository;
  final BudgetRepository budgetRepository;
  final ExpenseRepository expenseRepository;
  final BudgetExpenseFilter? budgetFilter;
  final DateTime Function() _now;

  Future<EnvelopeMonth> call() async {
    final all = (await expenseRepository.getExpenses())
        .where((e) => !e.isDeleted)
        .toList();
    return EnvelopeCalculator.compute(
      settings: repository.get(),
      limits: EnvelopeAdjustments.monthlyOnly(
        await budgetRepository.getLimits(),
        await budgetRepository.getPeriods(),
      ),
      expenses: budgetFilter?.forBudgets(all) ?? all,
      now: _now(),
    );
  }
}

enum EnvelopeMoveError { amount, sameEnvelope }

class MoveEnvelopeMoneyUseCase {
  MoveEnvelopeMoneyUseCase(this.repository, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final EnvelopeRepository repository;
  final DateTime Function() _now;

  /// Returns an error, or `null` once the move is saved. Moving more than an
  /// envelope holds is allowed (it goes negative), like covering a bill
  /// before payday.
  Future<EnvelopeMoveError?> call({
    required String from,
    required String to,
    required double amount,
  }) async {
    if (!amount.isFinite || amount <= 0) return EnvelopeMoveError.amount;
    if (from == to) return EnvelopeMoveError.sameEnvelope;
    final now = _now();
    await repository.addMove(
      EnvelopeMove(
        month: DateTime(now.year, now.month),
        fromCategoryId: from,
        toCategoryId: to,
        amount: double.parse(amount.toStringAsFixed(2)),
      ),
    );
    return null;
  }
}
