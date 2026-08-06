import '../../../../core/constants/expense_category.dart';
import '../../../expense/domain/entities/expense_entity.dart';
import '../entities/dashboard_summary.dart';

/// Pure aggregation for the dashboard. Kept in the domain layer so the
/// totals/sorting logic is unit-testable and independent of the widget tree.
class ComputeDashboardSummaryUseCase {
  const ComputeDashboardSummaryUseCase();

  DashboardSummary call(List<ExpenseEntity> expenses, {DateTime? now}) {
    final totalSpent = expenses.fold<double>(
      0,
      (sum, expense) => sum + expense.amount,
    );

    final latestExpenseByLabel = <String, DateTime>{};
    for (final expense in expenses) {
      final label = ExpenseCategories.byId(expense.categoryId).label;
      final existing = latestExpenseByLabel[label];
      if (existing == null || expense.date.isAfter(existing)) {
        latestExpenseByLabel[label] = expense.date;
      }
    }

    final sortedCategories = List<ExpenseCategory>.from(ExpenseCategories.all)
      ..removeWhere((cat) => !latestExpenseByLabel.containsKey(cat.label))
      ..sort(
        (a, b) => latestExpenseByLabel[b.label]!.compareTo(
          latestExpenseByLabel[a.label]!,
        ),
      );

    final referenceDate = now ?? DateTime.now();
    final thisMonthStart = DateTime(referenceDate.year, referenceDate.month, 1);
    final lastMonthStart = DateTime(
      referenceDate.year,
      referenceDate.month - 1,
      1,
    );

    double thisMonthSpent = 0;
    double lastMonthSpent = 0;
    for (final expense in expenses) {
      if (!expense.date.isBefore(thisMonthStart)) {
        thisMonthSpent += expense.amount;
      } else if (!expense.date.isBefore(lastMonthStart)) {
        lastMonthSpent += expense.amount;
      }
    }

    final String vsLastMonthLabel;
    if (lastMonthSpent > 0) {
      final change = ((thisMonthSpent - lastMonthSpent) / lastMonthSpent) * 100;
      final direction = change >= 0 ? '↑' : '↓';
      vsLastMonthLabel =
          '$direction ${change.abs().toStringAsFixed(0)}% vs last month';
    } else {
      vsLastMonthLabel = 'No spending last month';
    }

    return DashboardSummary(
      totalSpent: totalSpent,
      thisMonthSpent: thisMonthSpent,
      lastMonthSpent: lastMonthSpent,
      vsLastMonthLabel: vsLastMonthLabel,
      sortedCategories: List.unmodifiable(sortedCategories),
    );
  }
}
