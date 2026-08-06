import '../../domain/repositories/notification_repository.dart';

/// Marks every unread notification in the inbox as read.
class MarkAllNotificationsReadUseCase {
  final NotificationRepository repository;

  const MarkAllNotificationsReadUseCase(this.repository);

  Future<void> call() {
    return repository.markAllRead();
  }
}
