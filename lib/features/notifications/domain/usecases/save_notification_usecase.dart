import '../../domain/entities/app_notification.dart';
import '../../domain/repositories/notification_repository.dart';

/// Persists an incoming push notification to the in-app inbox.
class SaveNotificationUseCase {
  final NotificationRepository repository;

  const SaveNotificationUseCase(this.repository);

  Future<void> call(AppNotification notification) {
    return repository.save(notification);
  }
}
