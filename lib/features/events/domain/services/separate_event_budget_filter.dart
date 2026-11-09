import '../../../budget/domain/services/budget_expense_filter.dart';
import '../../../expense/domain/entities/expense_entity.dart';
import '../repositories/spending_event_repository.dart';

/// Drops expenses tagged with an event whose budget is kept separate.
/// Expenses of a deleted event count against budgets again.
class SeparateEventBudgetFilter implements BudgetExpenseFilter {
  SeparateEventBudgetFilter(this.repository);

  final SpendingEventRepository repository;

  @override
  List<ExpenseEntity> forBudgets(List<ExpenseEntity> expenses) {
    final separate = {
      for (final e in repository.getAll())
        if (e.separateFromBudgets) e.id,
    };
    if (separate.isEmpty) return expenses;
    return expenses
        .where((e) => e.eventId == null || !separate.contains(e.eventId))
        .toList();
  }
}
