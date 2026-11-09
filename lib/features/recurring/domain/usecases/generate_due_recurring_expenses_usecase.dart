import '../../../expense/domain/usecases/add_expense_usecase.dart';
import '../entities/recurring_expense_entity.dart';
import '../repositories/recurring_expense_repository.dart';
import '../services/recurrence_calculator.dart';
import 'start_recurring_expense_usecase.dart';

/// Turns every due occurrence of every active rule into a real expense.
///
/// Safe to run repeatedly (e.g. on each launch): expense ids are
/// deterministic per occurrence, and each rule's progress is saved after its
/// occurrences are written.
class GenerateDueRecurringExpensesUseCase {
  GenerateDueRecurringExpensesUseCase({
    required this.repository,
    required this.addExpense,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  /// Upper bound per rule per run, so a corrupt rule can never flood the
  /// expense list (a daily rule left alone for a year is 365).
  static const maxOccurrencesPerRun = 400;

  final RecurringExpenseRepository repository;
  final AddExpenseUseCase addExpense;
  final DateTime Function() _now;

  /// Returns the number of expenses created.
  Future<int> call() async {
    final now = _now();
    var created = 0;

    for (final rule in await repository.getAll()) {
      if (!rule.isActive) continue;
      created += await _generateFor(rule, now);
    }

    return created;
  }

  Future<int> _generateFor(RecurringExpenseEntity rule, DateTime now) async {
    var index = rule.generatedCount;
    var created = 0;
    var stillActive = true;

    while (created < maxOccurrencesPerRun) {
      final due = RecurrenceCalculator.occurrenceAt(
        start: rule.startDate,
        frequency: rule.frequency,
        interval: rule.interval,
        index: index,
      );

      final endDate = rule.endDate;
      if (endDate != null && due.isAfter(endDate)) {
        stillActive = false;
        break;
      }
      if (due.isAfter(now)) break;

      await addExpense(
        AddExpenseParams(
          id: StartRecurringExpenseUseCase.occurrenceId(rule.id, index),
          amount: rule.amount,
          currency: rule.currency,
          categoryId: rule.categoryId,
          note: rule.note,
          title: rule.title,
          merchant: rule.merchant,
          originalAmount: rule.originalAmount,
          exchangeRate: rule.exchangeRate,
          recurringId: rule.id,
          paymentMethod: rule.paymentMethod,
          taxTag: rule.taxTag,
          date: due,
        ),
      );

      index++;
      created++;
    }

    if (index != rule.generatedCount || stillActive != rule.isActive) {
      await repository.save(
        rule.copyWith(
          generatedCount: index,
          isActive: stillActive,
          updatedAt: now,
        ),
      );
    }

    return created;
  }
}
