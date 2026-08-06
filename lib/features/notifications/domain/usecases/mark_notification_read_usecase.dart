import '../../domain/repositories/notification_repository.dart';

/// Marks a single notification as read in the inbox.
class MarkNotificationReadUseCase {
  final NotificationRepository repository;

  const MarkNotificationReadUseCase(this.repository);

  Future<void> call(String id) {
    return repository.markRead(id);
  }
}
