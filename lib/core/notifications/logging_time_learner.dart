import 'dart:math' as math;

import '../../features/expense/domain/entities/expense_entity.dart';

/// Time of day the user habitually logs expenses.
class LoggingTime {
  const LoggingTime(this.hour, this.minute, {required this.learned});

  final int hour;
  final int minute;

  /// False when there wasn't enough history and this is the default.
  final bool learned;

  int get minuteOfDay => hour * 60 + minute;

  @override
  bool operator ==(Object other) =>
      other is LoggingTime &&
      other.hour == hour &&
      other.minute == minute &&
      other.learned == learned;

  @override
  int get hashCode => Object.hash(hour, minute, learned);

  @override
  String toString() => 'LoggingTime($hour:$minute, learned: $learned)';
}

/// Learns when the user usually logs expenses (from `createdAt`, not the
/// expense date) and plans reminders at that time.
///
/// * Only entries the user typed in count: recurring auto-logs are excluded.
/// * Recent behaviour matters more (exponential decay, [halfLife]).
/// * 30-minute buckets, smoothed with their neighbours, circular across
///   midnight; the reminder goes at the centre of the heaviest bucket.
/// * Needs [minEntries] entries over [minDays] distinct days, otherwise
///   falls back to [fallback] (9 PM).
/// * Clamped to a polite window ([earliest]–[latest]).
abstract final class LoggingTimeLearner {
  static const fallback = LoggingTime(21, 0, learned: false);
  static const lookback = Duration(days: 60);
  static const halfLife = Duration(days: 21);
  static const minEntries = 8;
  static const minDays = 5;
  static const earliest = 8 * 60;
  static const latest = 22 * 60 + 30;
  static const _bucket = 30;
  static const _buckets = 24 * 60 ~/ _bucket;

  static LoggingTime learn(List<ExpenseEntity> expenses, DateTime now) {
    final since = now.subtract(lookback);
    final entries = expenses
        .where(
          (e) =>
              !e.isDeleted &&
              e.recurringId == null &&
              e.createdAt.isAfter(since) &&
              !e.createdAt.isAfter(now),
        )
        .map((e) => e.createdAt.toLocal())
        .toList();

    final days = {for (final t in entries) DateTime(t.year, t.month, t.day)};
    if (entries.length < minEntries || days.length < minDays) return fallback;

    final weights = List<double>.filled(_buckets, 0);
    final decay = math.ln2 / halfLife.inMinutes;
    for (final t in entries) {
      final age = now.difference(t).inMinutes;
      weights[(t.hour * 60 + t.minute) ~/ _bucket] += math.exp(-decay * age);
    }

    var best = 0;
    var bestScore = -1.0;
    for (var b = 0; b < _buckets; b++) {
      final score =
          weights[b] +
          .5 * weights[(b - 1 + _buckets) % _buckets] +
          .5 * weights[(b + 1) % _buckets];
      if (score > bestScore) {
        bestScore = score;
        best = b;
      }
    }

    // Weighted mean of the minutes inside the winning bucket for a precise
    // time, then rounded to a quarter hour.
    var sum = 0.0;
    var weight = 0.0;
    for (final t in entries) {
      final m = t.hour * 60 + t.minute;
      if (m ~/ _bucket != best) continue;
      final w = math.exp(-decay * now.difference(t).inMinutes);
      sum += m * w;
      weight += w;
    }
    final centre = weight == 0 ? best * _bucket + _bucket / 2 : sum / weight;
    final rounded = ((centre / 15).round() * 15).clamp(earliest, latest);
    return LoggingTime(rounded ~/ 60, rounded % 60, learned: true);
  }

  /// The next [days] reminder instants at [time], skipping today when the
  /// user already logged something today or the time has passed.
  static List<DateTime> plan({
    required LoggingTime time,
    required List<ExpenseEntity> expenses,
    required DateTime now,
    int days = 14,
  }) {
    final today = DateTime(now.year, now.month, now.day);
    final loggedToday = expenses.any((e) {
      if (e.isDeleted || e.recurringId != null) return false;
      final c = e.createdAt.toLocal();
      return DateTime(c.year, c.month, c.day) == today;
    });

    final out = <DateTime>[];
    for (var d = 0; out.length < days; d++) {
      final at = DateTime(
        today.year,
        today.month,
        today.day + d,
        time.hour,
        time.minute,
      );
      if (d == 0 && (loggedToday || !at.isAfter(now))) continue;
      out.add(at);
    }
    return out;
  }
}
