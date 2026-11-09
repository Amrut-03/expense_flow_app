import 'package:equatable/equatable.dart';

import '../../../expense/domain/entities/expense_entity.dart';

/// Daily totals for one calendar month plus no-spend streaks.
class SpendingCalendar extends Equatable {
  /// First day of the month shown.
  final DateTime month;

  /// Spend per day of [month]; index 0 is the 1st.
  final List<double> dailyTotals;

  /// Highest single-day total in [month] (scales the heatmap).
  final double maxDaily;

  /// Consecutive no-spend days ending today. Today counts once it has no
  /// spend so far, so logging an expense today resets the streak to 0.
  final int currentNoSpendStreak;

  /// Longest run of no-spend days within [month], up to today.
  final int longestNoSpendStreakInMonth;

  /// No-spend days in [month], up to today.
  final int noSpendDaysInMonth;

  const SpendingCalendar({
    required this.month,
    required this.dailyTotals,
    required this.maxDaily,
    required this.currentNoSpendStreak,
    required this.longestNoSpendStreakInMonth,
    required this.noSpendDaysInMonth,
  });

  int get daysInMonth => dailyTotals.length;

  @override
  List<Object?> get props => [
    month,
    dailyTotals,
    maxDaily,
    currentNoSpendStreak,
    longestNoSpendStreakInMonth,
    noSpendDaysInMonth,
  ];

  /// Streaks never count days before the user's first expense; otherwise a
  /// brand-new user would start with a "streak" of years.
  static SpendingCalendar compute(
    List<ExpenseEntity> expenses, {
    required DateTime now,
    DateTime? month,
  }) {
    final today = _day(now);
    final shown = month == null
        ? DateTime(now.year, now.month)
        : DateTime(month.year, month.month);
    final daysInMonth = DateTime(shown.year, shown.month + 1, 0).day;

    final spendDays = <DateTime, double>{};
    DateTime? firstDay;
    for (final e in expenses) {
      if (e.isDeleted || e.amount <= 0) continue;
      final d = _day(e.date);
      spendDays.update(d, (v) => v + e.amount, ifAbsent: () => e.amount);
      if (firstDay == null || d.isBefore(firstDay)) firstDay = d;
    }

    final daily = [
      for (var i = 1; i <= daysInMonth; i++)
        spendDays[DateTime(shown.year, shown.month, i)] ?? 0.0,
    ];
    final maxDaily = daily.fold<double>(0, (m, v) => v > m ? v : m);

    // Current streak, walking back from today.
    var streak = 0;
    if (firstDay != null) {
      var d = today;
      while (!d.isBefore(firstDay) && !spendDays.containsKey(d)) {
        streak++;
        d = DateTime(d.year, d.month, d.day - 1);
      }
    }

    // Longest streak and no-spend count within the shown month.
    var longest = 0;
    var run = 0;
    var noSpend = 0;
    for (var i = 1; i <= daysInMonth; i++) {
      final d = DateTime(shown.year, shown.month, i);
      if (d.isAfter(today)) break;
      final tracked = firstDay != null && !d.isBefore(firstDay);
      if (tracked && !spendDays.containsKey(d)) {
        run++;
        noSpend++;
        if (run > longest) longest = run;
      } else {
        run = 0;
      }
    }

    return SpendingCalendar(
      month: shown,
      dailyTotals: daily,
      maxDaily: maxDaily,
      currentNoSpendStreak: streak,
      longestNoSpendStreakInMonth: longest,
      noSpendDaysInMonth: noSpend,
    );
  }

  static DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);
}
