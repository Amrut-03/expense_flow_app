import 'package:expense_flow_app/features/recurring/domain/entities/recurring_expense_entity.dart';
import 'package:expense_flow_app/features/recurring/domain/services/recurrence_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  DateTime at(
    DateTime start,
    RecurrenceFrequency frequency,
    int index, {
    int interval = 1,
  }) {
    return RecurrenceCalculator.occurrenceAt(
      start: start,
      frequency: frequency,
      interval: interval,
      index: index,
    );
  }

  group('RecurrenceCalculator.occurrenceAt', () {
    test('index 0 is the start date', () {
      final start = DateTime(2026, 3, 15, 9, 30);
      for (final f in RecurrenceFrequency.values) {
        expect(at(start, f, 0), start, reason: f.name);
      }
    });

    test('daily advances by calendar days and keeps the time', () {
      final start = DateTime(2026, 12, 30, 8);
      expect(at(start, RecurrenceFrequency.daily, 3), DateTime(2027, 1, 2, 8));
    });

    test('weekly with interval 2 is fortnightly', () {
      final start = DateTime(2026, 1, 1);
      expect(
        at(start, RecurrenceFrequency.weekly, 2, interval: 2),
        DateTime(2026, 1, 29),
      );
    });

    test('monthly clamps to month end without drifting', () {
      final start = DateTime(2026, 1, 31);
      expect(at(start, RecurrenceFrequency.monthly, 1), DateTime(2026, 2, 28));
      expect(at(start, RecurrenceFrequency.monthly, 2), DateTime(2026, 3, 31));
      expect(at(start, RecurrenceFrequency.monthly, 3), DateTime(2026, 4, 30));
    });

    test('monthly handles leap-year February', () {
      final start = DateTime(2027, 12, 31);
      expect(at(start, RecurrenceFrequency.monthly, 2), DateTime(2028, 2, 29));
    });

    test('monthly rolls over the year', () {
      final start = DateTime(2026, 11, 5);
      expect(at(start, RecurrenceFrequency.monthly, 3), DateTime(2027, 2, 5));
      expect(
        at(start, RecurrenceFrequency.monthly, 2, interval: 6),
        DateTime(2027, 11, 5),
      );
    });

    test('yearly clamps Feb 29 in non-leap years', () {
      final start = DateTime(2028, 2, 29);
      expect(at(start, RecurrenceFrequency.yearly, 1), DateTime(2029, 2, 28));
      expect(at(start, RecurrenceFrequency.yearly, 4), DateTime(2032, 2, 29));
    });
  });

  group('RecurrenceCalculator helpers', () {
    RecurringExpenseEntity rule({int generated = 0}) {
      return RecurringExpenseEntity(
        id: 'r',
        amount: 100,
        currency: 'INR',
        categoryId: 'bills',
        frequency: RecurrenceFrequency.monthly,
        startDate: DateTime(2026, 1, 10),
        generatedCount: generated,
        createdAt: DateTime(2026, 1, 10),
        updatedAt: DateTime(2026, 1, 10),
      );
    }

    test('nextDueDate uses generatedCount as the index', () {
      expect(
        RecurrenceCalculator.nextDueDate(rule(generated: 2)),
        DateTime(2026, 3, 10),
      );
    });

    test('firstIndexAfter skips everything on or before the moment', () {
      expect(
        RecurrenceCalculator.firstIndexAfter(rule(), DateTime(2026, 4, 10)),
        4,
      );
      expect(
        RecurrenceCalculator.firstIndexAfter(rule(), DateTime(2026, 4, 9)),
        3,
      );
    });

    test('daysInMonth', () {
      expect(RecurrenceCalculator.daysInMonth(2026, 2), 28);
      expect(RecurrenceCalculator.daysInMonth(2028, 2), 29);
      expect(RecurrenceCalculator.daysInMonth(2026, 12), 31);
    });
  });
}
