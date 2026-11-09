import '../../../categories/domain/services/category_suggester.dart';
import '../../../expense/domain/entities/expense_entity.dart';
import '../../../recurring/domain/entities/recurring_expense_entity.dart';
import '../../../recurring/domain/services/recurrence_calculator.dart';
import '../entities/detected_subscription.dart';

class _Cycle {
  const _Cycle(this.frequency, this.minDays, this.maxDays, this.minCharges);

  final RecurrenceFrequency frequency;
  final int minDays;
  final int maxDays;
  final int minCharges;
}

/// Finds subscriptions in expense history: charges from the same merchant
/// at a consistent amount on a regular weekly, monthly or yearly cycle.
abstract final class SubscriptionDetector {
  static const _cycles = [
    _Cycle(RecurrenceFrequency.weekly, 6, 8, 3),
    _Cycle(RecurrenceFrequency.monthly, 26, 35, 3),
    // Yearly needs only two charges; a third would take three years.
    _Cycle(RecurrenceFrequency.yearly, 350, 380, 2),
  ];

  /// Charges may vary by this much around the median (price changes, tax).
  static const amountTolerance = 0.15;

  /// Share of gaps that must fit the cycle (tolerates one skipped month).
  static const minRegularShare = 0.75;

  static List<DetectedSubscription> detect({
    required List<ExpenseEntity> expenses,
    required DateTime now,
    Set<String> trackedKeys = const {},
  }) {
    final groups = <String, List<ExpenseEntity>>{};
    for (final e in expenses) {
      if (e.isDeleted) continue;
      final key = keyOf(e);
      if (key.isEmpty) continue;
      groups.putIfAbsent(key, () => []).add(e);
    }

    final found = <DetectedSubscription>[];
    groups.forEach((key, charges) {
      final sub = _analyse(key, charges, now, trackedKeys);
      if (sub != null) found.add(sub);
    });

    found.sort((a, b) => b.monthlyCost.compareTo(a.monthlyCost));
    return found;
  }

  /// Grouping key for an expense: its normalised merchant, else title.
  static String keyOf(ExpenseEntity e) =>
      CategorySuggester.normalize(e.merchant ?? e.title ?? '');

  static DetectedSubscription? _analyse(
    String key,
    List<ExpenseEntity> charges,
    DateTime now,
    Set<String> trackedKeys,
  ) {
    if (charges.length < 2) return null;
    charges.sort((a, b) => a.date.compareTo(b.date));

    // Collapse same-day duplicates (e.g. a retry) into one charge.
    final distinct = <ExpenseEntity>[];
    for (final c in charges) {
      if (distinct.isNotEmpty && _sameDay(distinct.last.date, c.date)) continue;
      distinct.add(c);
    }
    if (distinct.length < 2) return null;

    final amounts = distinct.map((c) => c.amount).toList()..sort();
    final median = amounts[amounts.length ~/ 2];
    final consistent = distinct.every(
      (c) => (c.amount - median).abs() <= median * amountTolerance,
    );
    if (!consistent) return null;

    final gaps = <int>[
      for (var i = 1; i < distinct.length; i++)
        _days(distinct[i - 1].date, distinct[i].date),
    ];

    for (final cycle in _cycles) {
      if (distinct.length < cycle.minCharges) continue;

      final regular = gaps
          .where((g) => g >= cycle.minDays && g <= cycle.maxDays)
          .length;
      if (regular / gaps.length < minRegularShare) continue;

      final last = distinct.last;
      final next = _next(last.date, cycle.frequency);

      // Lapsed: no charge for well over one cycle, so it was likely
      // cancelled.
      final lapseLimit = _next(next, cycle.frequency);
      if (now.isAfter(lapseLimit)) return null;

      return DetectedSubscription(
        key: key,
        name: (last.merchant ?? last.title ?? key).trim(),
        categoryId: _mostCommon(distinct.map((c) => c.categoryId)),
        paymentMethod: last.paymentMethod,
        amount: median,
        frequency: cycle.frequency,
        occurrences: distinct.length,
        firstCharge: distinct.first.date,
        lastCharge: last.date,
        nextExpected: next,
        isTracked:
            trackedKeys.contains(key) ||
            distinct.any((c) => c.recurringId != null),
      );
    }

    return null;
  }

  static DateTime _next(DateTime from, RecurrenceFrequency f) {
    return RecurrenceCalculator.occurrenceAt(
      start: from,
      frequency: f,
      interval: 1,
      index: 1,
    );
  }

  static int _days(DateTime a, DateTime b) => DateTime.utc(
    b.year,
    b.month,
    b.day,
  ).difference(DateTime.utc(a.year, a.month, a.day)).inDays;

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static String _mostCommon(Iterable<String> values) {
    final counts = <String, int>{};
    for (final v in values) {
      counts.update(v, (c) => c + 1, ifAbsent: () => 1);
    }
    return counts.entries.reduce((a, b) => b.value > a.value ? b : a).key;
  }
}
