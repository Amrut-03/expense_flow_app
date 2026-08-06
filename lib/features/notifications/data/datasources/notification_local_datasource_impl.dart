import 'package:hive/hive.dart';

import '../models/app_notification_model.dart';
import 'notification_local_datasource.dart';

class NotificationLocalDataSourceImpl implements NotificationLocalDataSource {
  final Box<AppNotificationModel> box;

  NotificationLocalDataSourceImpl(this.box);

  @override
  Future<void> add(AppNotificationModel notification) async {
    await box.put(notification.id, notification);
  }

  @override
  Future<void> markRead(String id) async {
    final current = box.get(id);
    if (current == null || current.isRead) return;

    await box.put(id, current.copyWith(isRead: true));
  }

  @override
  Future<void> markAllRead() async {
    final unread = box.values.where((n) => !n.isRead).toList();
    for (final notification in unread) {
      await box.put(notification.id, notification.copyWith(isRead: true));
    }
  }

  @override
  Future<List<AppNotificationModel>> getAll() async {
    final notifications = box.values.toList();
    notifications.sort((a, b) => b.receivedAt.compareTo(a.receivedAt));
    return notifications;
  }

  @override
  Future<void> clear() async {
    await box.clear();
  }

  @override
  Stream<List<AppNotificationModel>> watch() {
    return Stream<List<AppNotificationModel>>.multi((controller) async {
      // Emit the current snapshot first; `box.watch()` alone never emits an
      // initial value and would leave a fresh/empty inbox in a perpetual
      // loading state.
      controller.add(_latest());

      await for (final _ in box.watch()) {
        controller.add(_latest());
      }
    });
  }

  List<AppNotificationModel> _latest() {
    final notifications = box.values.toList();
    notifications.sort((a, b) => b.receivedAt.compareTo(a.receivedAt));
    return notifications;
  }
}
