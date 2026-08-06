import '../entities/notification_settings.dart';
import '../repositories/notification_settings_repository.dart';

class GetNotificationSettingsUseCase {
  final NotificationSettingsRepository repository;

  const GetNotificationSettingsUseCase(this.repository);

  NotificationSettings call() => repository.getSettings();
}
