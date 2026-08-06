import 'package:equatable/equatable.dart';

/// The user's local enable/disable preference for each notification channel.
/// Stored in a dedicated Hive box so toggles take effect immediately and
/// survive restarts.
class NotificationSettings extends Equatable {
  final bool budgetAlertsEnabled;
  final bool dailyReminderEnabled;
  final bool weeklySummaryEnabled;
  final bool monthlySummaryEnabled;

  const NotificationSettings({
    this.budgetAlertsEnabled = true,
    this.dailyReminderEnabled = true,
    this.weeklySummaryEnabled = true,
    this.monthlySummaryEnabled = true,
  });

  NotificationSettings copyWith({
    bool? budgetAlertsEnabled,
    bool? dailyReminderEnabled,
    bool? weeklySummaryEnabled,
    bool? monthlySummaryEnabled,
  }) {
    return NotificationSettings(
      budgetAlertsEnabled: budgetAlertsEnabled ?? this.budgetAlertsEnabled,
      dailyReminderEnabled: dailyReminderEnabled ?? this.dailyReminderEnabled,
      weeklySummaryEnabled: weeklySummaryEnabled ?? this.weeklySummaryEnabled,
      monthlySummaryEnabled:
          monthlySummaryEnabled ?? this.monthlySummaryEnabled,
    );
  }

  @override
  List<Object?> get props => [
    budgetAlertsEnabled,
    dailyReminderEnabled,
    weeklySummaryEnabled,
    monthlySummaryEnabled,
  ];
}
