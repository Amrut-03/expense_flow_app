import 'package:equatable/equatable.dart';

import '../../../expense/domain/entities/expense_entity.dart';

class StatementLine extends Equatable {
  final String key;
  final double total;
  final int count;

  const StatementLine({
    required this.key,
    required this.total,
    required this.count,
  });

  double shareOf(double whole) => whole <= 0 ? 0 : total / whole;

  @override
  List<Object?> get props => [key, total, count];
}

/// Everything a monthly statement shows, computed from raw expenses.
class MonthlyStatement extends Equatable {
  /// First day of the month.
  final DateTime month;

  /// Non-deleted expenses in the month, oldest first.
  final List<ExpenseEntity> expenses;
  final double total;
  final double previousMonthTotal;

  /// Largest first.
  final List<StatementLine> byCategory;

  /// Largest first; expenses without a method count as `Other`.
  final List<StatementLine> byPaymentMethod;

  /// Total of tax-tagged expenses in the month.
  final double taxTaggedTotal;

  const MonthlyStatement({
    required this.month,
    required this.expenses,
    required this.total,
    required this.previousMonthTotal,
    required this.byCategory,
    required this.byPaymentMethod,
    required this.taxTaggedTotal,
  });

  bool get isEmpty => expenses.isEmpty;

  int get daysInMonth => DateTime(month.year, month.month + 1, 0).day;

  /// Per-day average over the days of the month that have passed (all of
  /// them for past months).
  double averagePerDay(DateTime now) {
    final isCurrent = now.year == month.year && now.month == month.month;
    final days = isCurrent ? now.day : daysInMonth;
    return days <= 0 ? 0 : total / days;
  }

  /// Change vs last month as a fraction (0.25 = 25% more), `null` when last
  /// month had no spending.
  double? get changeVsPreviousMonth => previousMonthTotal <= 0
      ? null
      : (total - previousMonthTotal) / previousMonthTotal;

  ExpenseEntity? get largest => expenses.isEmpty
      ? null
      : expenses.reduce((a, b) => b.amount > a.amount ? b : a);

  static MonthlyStatement compute(List<ExpenseEntity> all, DateTime month) {
    final start = DateTime(month.year, month.month);
    final end = DateTime(month.year, month.month + 1);
    final prevStart = DateTime(month.year, month.month - 1);

    final inMonth = <ExpenseEntity>[];
    var previous = 0.0;
    for (final e in all) {
      if (e.isDeleted) continue;
      if (!e.date.isBefore(start) && e.date.isBefore(end)) {
        inMonth.add(e);
      } else if (!e.date.isBefore(prevStart) && e.date.isBefore(start)) {
        previous += e.amount;
      }
    }
    inMonth.sort((a, b) => a.date.compareTo(b.date));

    return MonthlyStatement(
      month: start,
      expenses: inMonth,
      total: inMonth.fold(0, (s, e) => s + e.amount),
      previousMonthTotal: previous,
      byCategory: _group(inMonth, (e) => e.categoryId),
      byPaymentMethod: _group(inMonth, (e) => e.paymentMethod ?? 'Other'),
      taxTaggedTotal: inMonth
          .where((e) => e.taxTag != null)
          .fold(0, (s, e) => s + e.amount),
    );
  }

  static List<StatementLine> _group(
    List<ExpenseEntity> expenses,
    String Function(ExpenseEntity) keyOf,
  ) {
    final totals = <String, double>{};
    final counts = <String, int>{};
    for (final e in expenses) {
      final k = keyOf(e);
      totals.update(k, (v) => v + e.amount, ifAbsent: () => e.amount);
      counts.update(k, (v) => v + 1, ifAbsent: () => 1);
    }
    return [
      for (final k in totals.keys)
        StatementLine(key: k, total: totals[k]!, count: counts[k]!),
    ]..sort((a, b) => b.total.compareTo(a.total));
  }

  @override
  List<Object?> get props => [
    month,
    expenses,
    total,
    previousMonthTotal,
    byCategory,
    byPaymentMethod,
    taxTaggedTotal,
  ];
}
