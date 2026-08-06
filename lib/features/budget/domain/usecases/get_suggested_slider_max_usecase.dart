import '../../../expense/domain/entities/expense_entity.dart';

class GetSuggestedSliderMaxUseCase {
  static const double defaultMax = 10000;
  static const double multiplier = 1.5;

  Map<String, double> call(List<ExpenseEntity> expenses) {
    final monthlyTotals = <String, Map<String, double>>{};

    for (final expense in expenses) {
      final monthKey = '${expense.date.year}-${expense.date.month}';
      monthlyTotals.putIfAbsent(expense.categoryId, () => {});
      monthlyTotals[expense.categoryId]!.update(
        monthKey,
        (v) => v + expense.amount,
        ifAbsent: () => expense.amount,
      );
    }

    return monthlyTotals.map((categoryId, monthly) {
      final maxMonthly = monthly.values.fold<double>(
        0,
        (a, b) => a > b ? a : b,
      );
      return MapEntry(
        categoryId,
        (maxMonthly * multiplier).clamp(defaultMax, double.infinity),
      );
    });
  }
}
