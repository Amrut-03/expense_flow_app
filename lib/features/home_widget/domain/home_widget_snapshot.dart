import 'package:equatable/equatable.dart';

import '../../expense/domain/entities/expense_entity.dart';

/// What the home-screen widget shows. Strings are pre-formatted in Dart so
/// the native widgets stay dumb and match the app's currency/locale.
class HomeWidgetSnapshot extends Equatable {
  /// `yyyy-MM-dd` the numbers are for; the widget shows "open the app"
  /// instead of yesterday's figures once the date changes.
  final String date;

  /// e.g. `₹840` or `null` when the user has no budgets.
  final String? safeToSpend;
  final String spentToday;

  /// True when an over-budget state should be highlighted.
  final bool overBudget;

  /// App lock is on: show no amounts on the home screen.
  final bool hidden;

  const HomeWidgetSnapshot({
    required this.date,
    required this.safeToSpend,
    required this.spentToday,
    required this.overBudget,
    required this.hidden,
  });

  static String dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  static HomeWidgetSnapshot build({
    required DateTime now,
    required List<ExpenseEntity> expenses,
    required bool hasBudgets,
    required double safeToday,
    required int overBudgetCount,
    required String Function(double inr) format,
    required bool appLockEnabled,
  }) {
    final today = DateTime(now.year, now.month, now.day);
    final spent = expenses
        .where(
          (e) =>
              !e.isDeleted &&
              DateTime(e.date.year, e.date.month, e.date.day) == today,
        )
        .fold<double>(0, (s, e) => s + e.amount);
    return HomeWidgetSnapshot(
      date: dateKey(now),
      safeToSpend: hasBudgets ? format(safeToday < 0 ? 0 : safeToday) : null,
      spentToday: format(spent),
      overBudget: hasBudgets && (safeToday <= 0 || overBudgetCount > 0),
      hidden: appLockEnabled,
    );
  }

  @override
  List<Object?> get props => [date, safeToSpend, spentToday, overBudget, hidden];
}
