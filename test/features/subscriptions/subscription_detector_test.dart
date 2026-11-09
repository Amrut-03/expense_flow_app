import 'package:expense_flow_app/features/recurring/domain/entities/recurring_expense_entity.dart';
import 'package:expense_flow_app/features/subscriptions/domain/services/subscription_detector.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/expense_factory.dart';

void main() {
  final now = DateTime(2026, 11, 20);

  group('SubscriptionDetector', () {
    test('detects a monthly subscription and predicts the next charge', () {
      final subs = SubscriptionDetector.detect(
        expenses: [
          for (final m in [8, 9, 10, 11])
            expenseOf(
              amount: 649,
              date: DateTime(2026, m, 12),
              merchant: 'Netflix',
              categoryId: 'entertainment',
            ),
        ],
        now: now,
      );

      final netflix = subs.single;
      expect(netflix.name, 'Netflix');
      expect(netflix.frequency, RecurrenceFrequency.monthly);
      expect(netflix.amount, 649);
      expect(netflix.occurrences, 4);
      expect(netflix.nextExpected, DateTime(2026, 12, 12));
      expect(netflix.annualCost, 649 * 12);
      expect(netflix.isTracked, isFalse);
    });

    test('tolerates small price changes and one skipped month', () {
      final subs = SubscriptionDetector.detect(
        expenses: [
          expenseOf(
            amount: 199,
            date: DateTime(2026, 5, 3),
            merchant: 'Spotify',
          ),
          expenseOf(
            amount: 199,
            date: DateTime(2026, 6, 3),
            merchant: 'Spotify',
          ),
          expenseOf(
            amount: 199,
            date: DateTime(2026, 7, 3),
            merchant: 'Spotify',
          ),
          expenseOf(
            amount: 219,
            date: DateTime(2026, 8, 3),
            merchant: 'Spotify',
          ),
          // September skipped
          expenseOf(
            amount: 219,
            date: DateTime(2026, 10, 3),
            merchant: 'Spotify',
          ),
          expenseOf(
            amount: 219,
            date: DateTime(2026, 11, 3),
            merchant: 'Spotify',
          ),
        ],
        now: now,
      );
      expect(subs.single.frequency, RecurrenceFrequency.monthly);
    });

    test('detects weekly and yearly cycles', () {
      final subs = SubscriptionDetector.detect(
        expenses: [
          for (var i = 0; i < 4; i++)
            expenseOf(
              amount: 300,
              date: DateTime(2026, 10, 30).add(Duration(days: 7 * i)),
              merchant: 'Maid',
            ),
          expenseOf(
            amount: 1499,
            date: DateTime(2025, 11, 15),
            merchant: 'Prime Video',
          ),
          expenseOf(
            amount: 1499,
            date: DateTime(2026, 11, 15),
            merchant: 'Prime Video',
          ),
        ],
        now: DateTime(2026, 11, 21),
      );
      final byName = {for (final s in subs) s.name: s};
      expect(byName['Maid']!.frequency, RecurrenceFrequency.weekly);
      expect(byName['Prime Video']!.frequency, RecurrenceFrequency.yearly);
    });

    test('ignores irregular spending and inconsistent amounts', () {
      final subs = SubscriptionDetector.detect(
        expenses: [
          // Same merchant, wildly different amounts.
          for (final (m, a) in [
            (8, 120.0),
            (9, 980.0),
            (10, 45.0),
            (11, 600.0),
          ])
            expenseOf(
              amount: a,
              date: DateTime(2026, m, 12),
              merchant: 'Swiggy',
            ),
          // Consistent amount, irregular dates.
          expenseOf(amount: 50, date: DateTime(2026, 9, 1), merchant: 'Chai'),
          expenseOf(amount: 50, date: DateTime(2026, 9, 4), merchant: 'Chai'),
          expenseOf(amount: 50, date: DateTime(2026, 10, 20), merchant: 'Chai'),
        ],
        now: now,
      );
      expect(subs, isEmpty);
    });

    test('drops a subscription that has lapsed', () {
      final subs = SubscriptionDetector.detect(
        expenses: [
          for (final m in [1, 2, 3])
            expenseOf(
              amount: 99,
              date: DateTime(2026, m, 5),
              merchant: 'Gaana',
            ),
        ],
        now: now,
      );
      expect(subs, isEmpty);
    });

    test('marks subscriptions already covered by a recurring rule', () {
      final subs = SubscriptionDetector.detect(
        expenses: [
          for (final m in [8, 9, 10, 11])
            expenseOf(
              amount: 599,
              date: DateTime(2026, m, 1),
              merchant: 'Jio Fiber',
            ),
        ],
        now: now,
        trackedKeys: {'jio fiber'},
      );
      expect(subs.single.isTracked, isTrue);
    });

    test('collapses same-day duplicate charges', () {
      final subs = SubscriptionDetector.detect(
        expenses: [
          for (final m in [8, 9, 10, 11]) ...[
            expenseOf(
              amount: 649,
              date: DateTime(2026, m, 12, 9),
              merchant: 'Netflix',
            ),
            expenseOf(
              amount: 649,
              date: DateTime(2026, m, 12, 10),
              merchant: 'Netflix',
            ),
          ],
        ],
        now: now,
      );
      expect(subs.single.occurrences, 4);
    });
  });
}
