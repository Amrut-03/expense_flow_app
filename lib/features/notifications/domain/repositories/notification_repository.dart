import '../../domain/entities/app_notification.dart';

/// Gateway between the push pipeline / UI and the notification inbox.
abstract class NotificationRepository {
  Future<void> save(AppNotification notification);
  Future<void> markRead(String id);
  Future<void> markAllRead();
  Future<List<AppNotification>> getAll();
  Future<void> clear();
  Stream<List<AppNotification>> watch();
}
