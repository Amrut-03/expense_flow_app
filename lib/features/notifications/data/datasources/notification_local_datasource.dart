import '../models/app_notification_model.dart';

/// Local persistence for the in-app notification inbox (Hive box
/// `notifications_box`).
abstract class NotificationLocalDataSource {
  Future<void> add(AppNotificationModel notification);
  Future<void> markRead(String id);
  Future<void> markAllRead();
  Future<List<AppNotificationModel>> getAll();
  Future<void> clear();
  Stream<List<AppNotificationModel>> watch();
}
