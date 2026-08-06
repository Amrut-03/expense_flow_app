/// Shared date helpers used when computing spending summaries for the AI
/// index. Pure Dart so any domain layer can use them.
class SummaryDates {
  /// Returns midnight on the Monday of the week containing [date].
  static DateTime startOfWeek(DateTime date) {
    final day = DateTime(date.year, date.month, date.day);

    return day.subtract(Duration(days: day.weekday - 1));
  }

  /// Whether [date] falls within the calendar month [month].
  static bool sameMonth(DateTime date, DateTime month) {
    return date.year == month.year && date.month == month.month;
  }

  /// Formats a date as `YYYY-MM`.
  static String yyyymm(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}';
  }

  /// Formats a date as `YYYY-MM-DD`.
  static String yyyymmdd(DateTime date) {
    return '${yyyymm(date)}-${date.day.toString().padLeft(2, '0')}';
  }
}
