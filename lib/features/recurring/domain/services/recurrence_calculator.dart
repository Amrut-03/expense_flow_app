import '../entities/recurring_expense_entity.dart';

/// Pure date math for recurring expenses. No clock, no I/O.
abstract final class RecurrenceCalculator {
  /// The date of occurrence number [index] (0-based) of a schedule starting
  /// at [start].
  ///
  /// Monthly and yearly schedules clamp to the last day of shorter months
  /// while keeping the original anchor day for later months.
  static DateTime occurrenceAt({
    required DateTime start,
    required RecurrenceFrequency frequency,
    required int interval,
    required int index,
  }) {
    assert(interval >= 1, 'interval must be >= 1');
    assert(index >= 0, 'index must be >= 0');

    final steps = index * interval;

    switch (frequency) {
      case RecurrenceFrequency.daily:
        return _withDay(start, start.year, start.month, start.day + steps);
      case RecurrenceFrequency.weekly:
        return _withDay(start, start.year, start.month, start.day + 7 * steps);
      case RecurrenceFrequency.monthly:
        final monthIndex = start.month - 1 + steps;
        final year = start.year + monthIndex ~/ 12;
        final month = monthIndex % 12 + 1;
        return _clamped(start, year, month);
      case RecurrenceFrequency.yearly:
        return _clamped(start, start.year + steps, start.month);
    }
  }

  /// The next occurrence a rule has not generated yet.
  static DateTime nextDueDate(RecurringExpenseEntity rule) {
    return occurrenceAt(
      start: rule.startDate,
      frequency: rule.frequency,
      interval: rule.interval,
      index: rule.generatedCount,
    );
  }

  /// The smallest occurrence index whose date is strictly after [moment].
  /// Used to skip missed occurrences when a paused rule is resumed.
  static int firstIndexAfter(RecurringExpenseEntity rule, DateTime moment) {
    var index = rule.generatedCount;
    while (!occurrenceAt(
      start: rule.startDate,
      frequency: rule.frequency,
      interval: rule.interval,
      index: index,
    ).isAfter(moment)) {
      index++;
    }
    return index;
  }

  static int daysInMonth(int year, int month) {
    return DateTime(year, month + 1, 0).day;
  }

  static DateTime _clamped(DateTime start, int year, int month) {
    final day = start.day.clamp(1, daysInMonth(year, month));
    return _withDay(start, year, month, day);
  }

  // Calendar-field arithmetic (rather than Duration) keeps the wall-clock
  // time stable across DST changes.
  static DateTime _withDay(DateTime start, int year, int month, int day) {
    return DateTime(year, month, day, start.hour, start.minute, start.second);
  }
}
