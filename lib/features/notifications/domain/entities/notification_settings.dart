import 'package:equatable/equatable.dart';

/// The user's local enable/disable preference for each notification channel.
/// Stored in a dedicated Hive box so toggles take effect immediately and
/// survive restarts.
class NotificationSettings extends Equatable {
  final bool budgetAlertsEnabled;
  final bool dailyReminderEnabled;
  final bool weeklySummaryEnabled;
  final bool monthlySummaryEnabled;
  final bool billRemindersEnabled;

  /// "Logged ₹120 at Swiggy as Food — [OK] [Change]" after an SMS scan.
  final bool captureAlertsEnabled;

  const NotificationSettings({
    this.budgetAlertsEnabled = true,
    this.dailyReminderEnabled = true,
    this.weeklySummaryEnabled = true,
    this.monthlySummaryEnabled = true,
    this.billRemindersEnabled = true,
    this.captureAlertsEnabled = true,
  });

  NotificationSettings copyWith({
    bool? budgetAlertsEnabled,
    bool? dailyReminderEnabled,
    bool? weeklySummaryEnabled,
    bool? monthlySummaryEnabled,
    bool? billRemindersEnabled,
    bool? captureAlertsEnabled,
  }) {
    return NotificationSettings(
      budgetAlertsEnabled: budgetAlertsEnabled ?? this.budgetAlertsEnabled,
      dailyReminderEnabled: dailyReminderEnabled ?? this.dailyReminderEnabled,
      weeklySummaryEnabled: weeklySummaryEnabled ?? this.weeklySummaryEnabled,
      monthlySummaryEnabled:
          monthlySummaryEnabled ?? this.monthlySummaryEnabled,
      billRemindersEnabled: billRemindersEnabled ?? this.billRemindersEnabled,
      captureAlertsEnabled: captureAlertsEnabled ?? this.captureAlertsEnabled,
    );
  }

  @override
  List<Object?> get props => [
    budgetAlertsEnabled,
    dailyReminderEnabled,
    weeklySummaryEnabled,
    monthlySummaryEnabled,
    billRemindersEnabled,
    captureAlertsEnabled,
  ];
}
