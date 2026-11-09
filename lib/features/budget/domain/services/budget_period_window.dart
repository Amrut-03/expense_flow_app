import '../entities/budget_entity.dart';

/// The calendar window a budget period covers: `[start, end)`.
class BudgetPeriodWindow {
  final DateTime start;

  /// Exclusive end (midnight of the first day after the period).
  final DateTime end;

  const BudgetPeriodWindow(this.start, this.end);

  /// Monthly = calendar month, quarterly = calendar quarter, yearly =
  /// calendar year. Returns `null` for [BudgetPeriod.noLimit].
  static BudgetPeriodWindow? of(BudgetPeriod period, DateTime now) {
    switch (period) {
      case BudgetPeriod.monthly:
        return BudgetPeriodWindow(
          DateTime(now.year, now.month),
          DateTime(now.year, now.month + 1),
        );
      case BudgetPeriod.quarterly:
        final startMonth = ((now.month - 1) ~/ 3) * 3 + 1;
        return BudgetPeriodWindow(
          DateTime(now.year, startMonth),
          DateTime(now.year, startMonth + 3),
        );
      case BudgetPeriod.yearly:
        return BudgetPeriodWindow(DateTime(now.year), DateTime(now.year + 1));
      case BudgetPeriod.noLimit:
        return null;
    }
  }

  bool contains(DateTime date) => !date.isBefore(start) && date.isBefore(end);

  /// Whole calendar days in the window.
  int get totalDays => _daysBetween(start, end);

  /// Days elapsed including today (1 on the first day).
  int daysElapsed(DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    return (_daysBetween(start, today) + 1).clamp(1, totalDays);
  }

  /// Days remaining including today (1 on the last day).
  int daysLeft(DateTime now) => totalDays - daysElapsed(now) + 1;

  // Calendar-day difference that ignores DST hour shifts.
  static int _daysBetween(DateTime a, DateTime b) {
    return DateTime.utc(
      b.year,
      b.month,
      b.day,
    ).difference(DateTime.utc(a.year, a.month, a.day)).inDays;
  }
}
