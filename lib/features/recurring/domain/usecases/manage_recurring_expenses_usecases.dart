import '../entities/recurring_expense_entity.dart';
import '../repositories/recurring_expense_repository.dart';
import '../services/recurrence_calculator.dart';

class GetRecurringExpensesUseCase {
  const GetRecurringExpensesUseCase(this.repository);

  final RecurringExpenseRepository repository;

  /// Active rules first, then by next due date.
  Future<List<RecurringExpenseEntity>> call() async {
    final rules = await repository.getAll();
    rules.sort((a, b) {
      if (a.isActive != b.isActive) return a.isActive ? -1 : 1;
      return RecurrenceCalculator.nextDueDate(
        a,
      ).compareTo(RecurrenceCalculator.nextDueDate(b));
    });
    return rules;
  }
}

class WatchRecurringExpensesUseCase {
  const WatchRecurringExpensesUseCase(this.repository);

  final RecurringExpenseRepository repository;

  Stream<void> call() => repository.watch();
}

/// Pauses or resumes a rule. Resuming skips occurrences missed while paused,
/// so the user is not hit with a backlog of entries.
class SetRecurringExpenseActiveUseCase {
  SetRecurringExpenseActiveUseCase(this.repository, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final RecurringExpenseRepository repository;
  final DateTime Function() _now;

  Future<void> call(String id, {required bool active}) async {
    final rule = await repository.getById(id);
    if (rule == null || rule.isActive == active) return;

    final now = _now();

    await repository.save(
      rule.copyWith(
        isActive: active,
        generatedCount: active
            ? RecurrenceCalculator.firstIndexAfter(rule, now)
            : rule.generatedCount,
        updatedAt: now,
      ),
    );
  }
}

/// Deletes a rule. Expenses it already generated are kept.
class DeleteRecurringExpenseUseCase {
  const DeleteRecurringExpenseUseCase(this.repository);

  final RecurringExpenseRepository repository;

  Future<void> call(String id) => repository.delete(id);
}
