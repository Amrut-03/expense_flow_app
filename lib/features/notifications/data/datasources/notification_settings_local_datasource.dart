import 'package:hive/hive.dart';
import '../../domain/entities/notification_settings.dart';

/// Persists [NotificationSettings] in a dedicated Hive box so notification
/// enable/disable toggles survive restarts and are respected at scheduling
/// time.
abstract class NotificationSettingsLocalDataSource {
  NotificationSettings read();

  Future<void> write(NotificationSettings settings);
}

/// Keys mirror the field names on [NotificationSettings] for readability.
class NotificationSettingsLocalDataSourceImpl
    implements NotificationSettingsLocalDataSource {
  static const _boxName = 'notification_settings_box';

  static const _budgetAlerts = 'budget_alerts_enabled';
  static const _dailyReminder = 'daily_reminder_enabled';
  static const _weeklySummary = 'weekly_summary_enabled';
  static const _monthlySummary = 'monthly_summary_enabled';

  final Box<dynamic> _box = Hive.box<dynamic>(_boxName);

  @override
  NotificationSettings read() {
    return NotificationSettings(
      budgetAlertsEnabled:
          _box.get(_budgetAlerts, defaultValue: true) as bool? ?? true,
      dailyReminderEnabled:
          _box.get(_dailyReminder, defaultValue: true) as bool? ?? true,
      weeklySummaryEnabled:
          _box.get(_weeklySummary, defaultValue: true) as bool? ?? true,
      monthlySummaryEnabled:
          _box.get(_monthlySummary, defaultValue: true) as bool? ?? true,
    );
  }

  @override
  Future<void> write(NotificationSettings settings) async {
    await _box.put(_budgetAlerts, settings.budgetAlertsEnabled);
    await _box.put(_dailyReminder, settings.dailyReminderEnabled);
    await _box.put(_weeklySummary, settings.weeklySummaryEnabled);
    await _box.put(_monthlySummary, settings.monthlySummaryEnabled);
  }
}
