import '../entities/notification_settings.dart';
import '../repositories/notification_settings_repository.dart';

class UpdateNotificationSettingsUseCase {
  final NotificationSettingsRepository repository;

  const UpdateNotificationSettingsUseCase(this.repository);

  Future<void> call(NotificationSettings settings) =>
      repository.updateSettings(settings);
}
