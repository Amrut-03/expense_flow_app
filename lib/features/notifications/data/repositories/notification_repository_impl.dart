import '../../domain/entities/app_notification.dart';
import '../../domain/repositories/notification_repository.dart';
import '../datasources/notification_local_datasource.dart';
import '../models/app_notification_model.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  final NotificationLocalDataSource localDataSource;

  NotificationRepositoryImpl(this.localDataSource);

  @override
  Future<void> save(AppNotification notification) {
    return localDataSource.add(AppNotificationModel.fromEntity(notification));
  }

  @override
  Future<void> markRead(String id) {
    return localDataSource.markRead(id);
  }

  @override
  Future<void> markAllRead() {
    return localDataSource.markAllRead();
  }

  @override
  Future<List<AppNotification>> getAll() async {
    final models = await localDataSource.getAll();
    return models.map((model) => model.toEntity()).toList();
  }

  @override
  Future<void> clear() {
    return localDataSource.clear();
  }

  @override
  Stream<List<AppNotification>> watch() {
    return localDataSource.watch().map(
      (models) => models.map((model) => model.toEntity()).toList(),
    );
  }
}
