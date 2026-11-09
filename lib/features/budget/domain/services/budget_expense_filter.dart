import '../../../expense/domain/entities/expense_entity.dart';

/// Removes expenses that shouldn't count against monthly category budgets
/// (e.g. spending on a trip that has its own budget).
abstract interface class BudgetExpenseFilter {
  List<ExpenseEntity> forBudgets(List<ExpenseEntity> expenses);
}
