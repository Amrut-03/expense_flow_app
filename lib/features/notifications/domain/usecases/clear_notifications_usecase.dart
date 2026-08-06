import '../../domain/repositories/notification_repository.dart';

/// Clears the in-app notification inbox.
class ClearNotificationsUseCase {
  final NotificationRepository repository;

  const ClearNotificationsUseCase(this.repository);

  Future<void> call() {
    return repository.clear();
  }
}
