import 'package:timezone/timezone.dart' as tz;

import '../../core/notifications/amount_formatter.dart';
import '../../core/notifications/local_notification_service.dart';
import '../../core/notifications/notification_payload.dart';
import '../../features/expense/domain/entities/expense_entity.dart';
import '../../features/expense/domain/repositories/expense_repository.dart';
import '../../features/notifications/domain/entities/notification_settings.dart';
import '../../features/notifications/domain/entities/notification_type.dart';
import '../../features/notifications/domain/repositories/notification_settings_repository.dart';

/// Schedules the recurring local notifications (Tier 1 + Tier 2, client-side):
///   - a daily expense-logging reminder,
///   - a weekly spending summary (Monday 8 AM),
///   - a monthly spending summary (1st, 8 AM).
///
/// Summaries are computed from local data at scheduling time and re-scheduled
/// on every app launch so the numbers are as fresh as the last time the app
/// was used. Scheduled delivery requires no server and no billing.
class NotificationScheduler {
  static const int dailyReminderId = 1000;
  static const int weeklySummaryId = 1001;
  static const int monthlySummaryId = 1002;

  final LocalNotificationService notifications;
  final ExpenseRepository expenseRepository;
  final NotificationSettingsRepository settingsRepository;

  const NotificationScheduler({
    required this.notifications,
    required this.expenseRepository,
    required this.settingsRepository,
  });

  Future<void> scheduleAll() async {
    final settings = settingsRepository.getSettings();
    await _scheduleDailyReminder(settings);
    await _scheduleWeeklySummary(settings);
    await _scheduleMonthlySummary(settings);
  }

  Future<void> _scheduleDailyReminder(NotificationSettings settings) async {
    if (!settings.dailyReminderEnabled) {
      await notifications.cancel(id: dailyReminderId);
      return;
    }

    const hour = 21;
    const minute = 0;

    // final hour = DateTime.now().hour;
    // final minute = (DateTime.now().minute + 1) % 60;

    final payload = NotificationPayload(
      type: NotificationType.general,
      title: 'Time to log your expenses',
      message: 'Did you spend today? A quick entry keeps your budget accurate.',
      emoji: '✏️',
    );

    await notifications.scheduleDaily(
      id: dailyReminderId,
      title: payload.title,
      body: payload.message,
      channelId: NotificationChannels.reminders,
      hour: hour,
      minute: minute,
      payload: payload.encode(),
    );
  }

  Future<void> _scheduleWeeklySummary(NotificationSettings settings) async {
    if (!settings.weeklySummaryEnabled) {
      await notifications.cancel(id: weeklySummaryId);
      return;
    }

    final expenses = await expenseRepository.getExpenses();
    final since = DateTime.now().subtract(const Duration(days: 7));

    final filtered = expenses
        .where((e) => !e.isDeleted && e.date.isAfter(since))
        .toList();

    final payload = NotificationPayload(
      type: NotificationType.weeklySummary,
      title: 'Weekly spending summary',
      message: _summaryBody(filtered),
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
