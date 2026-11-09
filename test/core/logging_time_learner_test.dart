import 'package:expense_flow_app/core/notifications/logging_time_learner.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/expense_factory.dart';

void main() {
  final now = DateTime(2026, 11, 9, 12);

  test('falls back to 9 PM without enough history', () {
    final few = [
      for (var d = 1; d <= 3; d++)
        expenseOf(amount: 10, date: DateTime(2026, 11, 9 - d, 13, 10)),
    ];
    expect(LoggingTimeLearner.learn(few, now), LoggingTimeLearner.fallback);
  });

  test('learns the habitual time, rounded to a quarter hour', () {
    final expenses = [
      for (var d = 1; d <= 12; d++)
        expenseOf(amount: 10, date: DateTime(2026, 11, 9 - d, 20, 40 + d % 5)),
      // A few scattered outliers.
      expenseOf(amount: 5, date: DateTime(2026, 11, 2, 9, 5)),
      expenseOf(amount: 5, date: DateTime(2026, 11, 3, 14, 20)),
    ];
    final time = LoggingTimeLearner.learn(expenses, now);
    expect(time.learned, isTrue);
    expect((time.hour, time.minute), (20, 45));
  });

  test('recent habit outweighs an old one', () {
    final expenses = [
      // Old habit: 10 entries at 1 PM, 40-55 days ago.
      for (var d = 40; d < 50; d++)
        expenseOf(amount: 10, date: now.subtract(Duration(days: d)).copyWith(
          hour: 13,
          minute: 0,
        )),
      // New habit: 7 entries at 10 PM in the last week.
      for (var d = 1; d <= 7; d++)
        expenseOf(amount: 10, date: now.subtract(Duration(days: d)).copyWith(
          hour: 22,
          minute: 0,
        )),
    ];
    expect(LoggingTimeLearner.learn(expenses, now).hour, 22);
  });

  test('ignores recurring auto-logs and clamps to a polite window', () {
    final expenses = [
      for (var d = 1; d <= 10; d++)
        expenseOf(amount: 10, date: DateTime(2026, 11, 9 - d, 1, 30)),
      for (var d = 1; d <= 10; d++)
        expenseOf(
          amount: 10,
          date: DateTime(2026, 11, 9 - d, 18),
          recurringId: 'rent',
        ),
    ];
    final time = LoggingTimeLearner.learn(expenses, now);
    expect(time.minuteOfDay, LoggingTimeLearner.earliest);
  });

  group('plan', () {
    const time = LoggingTime(20, 30, learned: true);

    test('includes today when nothing was logged yet', () {
      final plan = LoggingTimeLearner.plan(
        time: time,
        expenses: const [],
        now: now,
        days: 3,
      );
      expect(plan, [
        DateTime(2026, 11, 9, 20, 30),
        DateTime(2026, 11, 10, 20, 30),
        DateTime(2026, 11, 11, 20, 30),
      ]);
    });

    test('skips today once the user logged something', () {
      final plan = LoggingTimeLearner.plan(
        time: time,
        expenses: [expenseOf(amount: 50, date: DateTime(2026, 11, 9, 9))],
        now: now,
        days: 2,
      );
      expect(plan.first, DateTime(2026, 11, 10, 20, 30));
      expect(plan, hasLength(2));
    });

    test('skips today when the time has passed', () {
      final plan = LoggingTimeLearner.plan(
        time: time,
        expenses: const [],
        now: DateTime(2026, 11, 9, 21),
        days: 1,
      );
      expect(plan.single, DateTime(2026, 11, 10, 20, 30));
    });
  });
}
