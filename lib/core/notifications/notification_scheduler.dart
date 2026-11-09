import 'dart:async';

import 'package:timezone/timezone.dart' as tz;

import '../../core/notifications/amount_formatter.dart';
import '../../core/notifications/local_notification_service.dart';
import '../../core/notifications/logging_time_learner.dart';
import '../../core/notifications/notification_payload.dart';
import '../../features/expense/domain/entities/expense_entity.dart';
import '../../features/expense/domain/repositories/expense_repository.dart';
import '../../features/notifications/domain/entities/notification_settings.dart';
import '../../features/notifications/domain/entities/notification_type.dart';
import '../../features/notifications/domain/repositories/notification_settings_repository.dart';
import '../../features/insights/domain/usecases/weekly_digest_usecase.dart';
import '../../features/recurring/domain/repositories/recurring_expense_repository.dart';
import '../../features/recurring/domain/services/bill_reminder_planner.dart';

/// Schedules the recurring local notifications (Tier 1 + Tier 2, client-side):
///   - expense-logging reminders at the user's learned usual time,
///   - a weekly digest (Monday 8 AM),
///   - a monthly spending summary (1st, 8 AM),
///   - "due tomorrow" reminders for recurring bills, rent and EMIs.
///
/// Summaries are computed from local data at scheduling time and re-scheduled
/// on every app launch so the numbers are as fresh as the last time the app
/// was used. Scheduled delivery requires no server and no billing.
class NotificationScheduler {
  /// Legacy fixed 9 PM repeating reminder; cancelled on every plan.
  static const int dailyReminderId = 1000;

  /// Smart logging reminders use ids `[loggingReminderBaseId, + count)`.
  static const int loggingReminderBaseId = 1100;
  static const int loggingReminderCount = 14;
  static const int weeklySummaryId = 1001;
  static const int monthlySummaryId = 1002;

  /// Bill reminders use ids `[billReminderBaseId, + maxReminders)`.
  static const int billReminderBaseId = 2000;

  final LocalNotificationService notifications;
  final ExpenseRepository expenseRepository;
  final NotificationSettingsRepository settingsRepository;
  final RecurringExpenseRepository recurringRepository;
  final GenerateWeeklyDigestUseCase weeklyDigest;
  final DateTime Function() _now;

  NotificationScheduler({
    required this.notifications,
    required this.expenseRepository,
    required this.settingsRepository,
    required this.recurringRepository,
    required this.weeklyDigest,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  Future<void> scheduleAll() async {
    final settings = settingsRepository.getSettings();
    await scheduleLoggingReminders();
    await scheduleWeeklySummary();
    await _scheduleMonthlySummary(settings);
    await scheduleBillReminders();
  }

  /// Re-plans every bill reminder from the current recurring rules.
  Future<void> scheduleBillReminders() async {
    for (var i = 0; i < BillReminderPlanner.maxReminders; i++) {
      await notifications.cancel(id: billReminderBaseId + i);
    }
    if (!settingsRepository.getSettings().billRemindersEnabled) return;

    final reminders = BillReminderPlanner.plan(
      await recurringRepository.getAll(),
      now: _now(),
    );

    for (var i = 0; i < reminders.length; i++) {
      final r = reminders[i];
      final payload = NotificationPayload(
        type: NotificationType.billReminder,
        title: '${r.label} due tomorrow',
        message:
            '${formatInr(r.amount)} will be logged automatically. Make sure '
            'your account has enough balance.',
        emoji: '🧾',
      );
      await notifications.scheduleAt(
        id: billReminderBaseId + i,
        title: payload.title,
        body: payload.message,
        channelId: NotificationChannels.reminders,
        date: tz.TZDateTime.from(r.remindAt, tz.local),
        payload: payload.encode(),
      );
    }
  }

  /// Learned usual logging time (or the 9 PM default).
  Future<LoggingTime> loggingTime() async =>
      LoggingTimeLearner.learn(await expenseRepository.getExpenses(), _now());

  /// Plans the next [LoggingTimeLearner.plan] reminders at the user's usual
  /// logging time as one-shots, so a day they already logged gets no nudge.
  /// Re-run on launch and whenever expenses change.
  Future<void> scheduleLoggingReminders() async {
    await notifications.cancel(id: dailyReminderId);
    for (var i = 0; i < loggingReminderCount; i++) {
      await notifications.cancel(id: loggingReminderBaseId + i);
    }
    if (!settingsRepository.getSettings().dailyReminderEnabled) return;

    final expenses = await expenseRepository.getExpenses();
    final now = _now();
    final time = LoggingTimeLearner.learn(expenses, now);
    final instants = LoggingTimeLearner.plan(
      time: time,
      expenses: expenses,
      now: now,
      days: loggingReminderCount,
    );

    final payload = NotificationPayload(
      type: NotificationType.general,
      title: 'Time to log your expenses',
      message: time.learned
          ? 'Your usual logging time. Anything spent today? It takes 5 '
                'seconds.'
          : 'Did you spend today? A quick entry keeps your budget accurate.',
      emoji: '✏️',
    );
    for (var i = 0; i < instants.length; i++) {
      await notifications.scheduleAt(
        id: loggingReminderBaseId + i,
        title: payload.title,
        body: payload.message,
        channelId: NotificationChannels.reminders,
        date: tz.TZDateTime.from(instants[i], tz.local),
        payload: payload.encode(),
      );
    }
  }

  StreamSubscription<void>? _expenseChanges;
  Timer? _replanDebounce;

  /// Re-plans logging reminders (debounced) whenever [changes] fires, so
  /// logging an expense cancels today's nudge.
  void watchExpenses(Stream<void> changes) {
    _expenseChanges ??= changes.listen((_) {
      _replanDebounce?.cancel();
      _replanDebounce = Timer(const Duration(seconds: 3), () {
        unawaited(scheduleLoggingReminders().catchError((Object _) {}));
      });
    });
  }

  /// Schedules next Monday's digest. Pass [digest] when a fresh
  /// (possibly model-written) one is available; otherwise the template or
  /// last cached rewrite is used without starting the model.
  Future<void> scheduleWeeklySummary({WeeklyDigest? digest}) async {
    final settings = settingsRepository.getSettings();
    if (!settings.weeklySummaryEnabled) {
      await notifications.cancel(id: weeklySummaryId);
      return;
    }

    final content = digest ?? await weeklyDigest(allowModel: false);

    final payload = NotificationPayload(
      type: NotificationType.weeklySummary,
      title: 'Your weekly digest',
      message: content.body,
      emoji: '📊',
    );

    await notifications.cancel(id: weeklySummaryId);
    await notifications.scheduleAt(
      id: weeklySummaryId,
      title: payload.title,
      body: payload.message,
      channelId: NotificationChannels.summaries,
      date: _nextWeekday(DateTime.monday, 8, 0),
      payload: payload.encode(),
    );
  }

  Future<void> _scheduleMonthlySummary(NotificationSettings settings) async {
    if (!settings.monthlySummaryEnabled) {
      await notifications.cancel(id: monthlySummaryId);
      return;
    }

    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month - 1, 1);
    final monthEnd = DateTime(now.year, now.month, 1);

    final expenses = await expenseRepository.getExpenses();
    final filtered = expenses
        .where(
          (e) =>
              !e.isDeleted &&
              !e.date.isBefore(monthStart) &&
              e.date.isBefore(monthEnd),
        )
        .toList();

    final payload = NotificationPayload(
      type: NotificationType.monthlySummary,
      title: 'Monthly spending summary',
      message: _summaryBody(filtered),
      emoji: '📈',
    );

    final firstOfNextMonth = DateTime(now.year, now.month + 1, 1);

    await notifications.cancel(id: monthlySummaryId);
    await notifications.scheduleAt(
      id: monthlySummaryId,
      title: payload.title,
      body: payload.message,
      channelId: NotificationChannels.summaries,
      date: tz.TZDateTime(
        tz.local,
        firstOfNextMonth.year,
        firstOfNextMonth.month,
        firstOfNextMonth.day,
        8,
        0,
      ),
      payload: payload.encode(),
    );
  }

  String _summaryBody(List<ExpenseEntity> expenses) {
    final total = expenses.fold<double>(0, (sum, e) => sum + e.amount);
    final count = expenses.length;
    return 'You spent ${formatInr(total)} across $count '
        'transaction${count == 1 ? '' : 's'}.';
  }

  tz.TZDateTime _nextWeekday(int weekday, int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var date = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    var daysUntil = weekday - now.weekday;
    if (daysUntil <= 0) daysUntil += 7;

    return date.add(Duration(days: daysUntil));
  }
}
