import '../entities/notification_settings.dart';

/// Contract for reading/updating the user's notification preferences.
abstract class NotificationSettingsRepository {
  NotificationSettings getSettings();

  Future<void> updateSettings(NotificationSettings settings);
}
