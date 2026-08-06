import 'package:equatable/equatable.dart';
import '../../../../core/constants/expense_category.dart';

class DashboardSummary extends Equatable {
  final double totalSpent;
  final double thisMonthSpent;
  final double lastMonthSpent;
  final String vsLastMonthLabel;
  final List<ExpenseCategory> sortedCategories;

  const DashboardSummary({
    required this.totalSpent,
    required this.thisMonthSpent,
    required this.lastMonthSpent,
    required this.vsLastMonthLabel,
    required this.sortedCategories,
  });

  @override
  List<Object?> get props => [
    totalSpent,
    thisMonthSpent,
    lastMonthSpent,
    vsLastMonthLabel,
    sortedCategories,
  ];
}
