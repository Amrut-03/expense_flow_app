import 'package:equatable/equatable.dart';

import '../entities/recurring_expense_entity.dart';
import 'recurrence_calculator.dart';

/// One reminder for an upcoming recurring charge.
class BillReminder extends Equatable {
  final String ruleId;
  final String label;
  final double amount;
  final String categoryId;

  /// When the charge falls due (and is auto-logged).
  final DateTime dueDate;

  /// When the reminder fires.
  final DateTime remindAt;

  const BillReminder({
    required this.ruleId,
    required this.label,
    required this.amount,
    required this.categoryId,
    required this.dueDate,
    required this.remindAt,
  });

  @override
  List<Object?> get props => [ruleId, amount, dueDate, remindAt];
}

/// Plans "due tomorrow" reminders for recurring bills, rent and EMIs.
abstract final class BillReminderPlanner {
  /// Reminders are fired this long before the due date…
  static const leadDays = 1;

  /// …at this hour.
  static const remindHour = 9;

  /// Only the next couple of weeks are scheduled; the plan is rebuilt on
  /// every launch and whenever a rule changes.
  static const horizon = Duration(days: 21);

  /// Hard cap so a pile of daily rules can't exhaust the OS alarm budget.
  static const maxReminders = 40;

  /// Daily rules are skipped: a reminder every day is noise, not help.
  static List<BillReminder> plan(
    List<RecurringExpenseEntity> rules, {
    required DateTime now,
  }) {
    final until = now.add(horizon);
    final reminders = <BillReminder>[];

    for (final rule in rules) {
      if (!rule.isActive || rule.frequency == RecurrenceFrequency.daily) {
        continue;
      }

      for (var i = rule.generatedCount; ; i++) {
        final due = RecurrenceCalculator.occurrenceAt(
          start: rule.startDate,
          frequency: rule.frequency,
          interval: rule.interval,
          index: i,
        );
        final end = rule.endDate;
        if (due.isAfter(until) || (end != null && due.isAfter(end))) break;

        final remindAt = DateTime(
          due.year,
          due.month,
          due.day - leadDays,
          remindHour,
        );
        if (remindAt.isAfter(now)) {
          reminders.add(
            BillReminder(
              ruleId: rule.id,
              label: _label(rule),
              amount: rule.amount,
              categoryId: rule.categoryId,
              dueDate: due,
              remindAt: remindAt,
            ),
          );
        }
      }
    }

    reminders.sort((a, b) => a.remindAt.compareTo(b.remindAt));
    return reminders.length > maxReminders
        ? reminders.sublist(0, maxReminders)
        : reminders;
  }

  static String _label(RecurringExpenseEntity rule) {
    for (final candidate in [rule.title, rule.merchant]) {
      if (candidate != null && candidate.trim().isNotEmpty) {
        return candidate.trim();
      }
    }
    return 'Recurring payment';
  }
}
