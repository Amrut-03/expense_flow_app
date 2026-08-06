/// The kind of push notification a user can receive.
///
/// Mirrors the `type` field sent in the FCM `data` payload by the server.
/// Keeping this in domain lets both the receive pipeline (routing) and any
/// future UI logic depend on a single, strongly typed source of truth.
enum NotificationType {
  /// Tier 1 — a category budget crossed a threshold (80% / 100%).
  budgetAlert('budget_alert', '🎯', '/budget'),

  /// Tier 1 — a category is spending well above its monthly average.
  categoryOverspend('category_overspend', '⚠️', '/budget'),

  /// Tier 2 — scheduled weekly spend summary.
  weeklySummary('weekly_summary', '📊', '/notifications'),

  /// Tier 2 — scheduled monthly spend summary.
  monthlySummary('monthly_summary', '📈', '/notifications'),

  /// Tier 3 — AI/insight notifications.
  insight('insight', '💡', '/notifications'),

  /// Data sync / backup status.
  sync('sync', '🔄', '/notifications'),

  /// Fallback for unknown or plain messages.
  general('general', '🔔', '/notifications');

  const NotificationType(this.fcmName, this.defaultEmoji, this.defaultRoute);

  /// The `type` value used in the FCM data payload.
  final String fcmName;

  /// Default emoji shown when the payload does not carry one.
  final String defaultEmoji;

  /// In-app route to open when the notification is tapped.
  final String defaultRoute;

  static NotificationType fromName(String? name) {
    if (name == null || name.isEmpty) return NotificationType.general;

    return NotificationType.values.firstWhere(
      (type) => type.fcmName == name,
      orElse: () => NotificationType.general,
    );
  }
}
