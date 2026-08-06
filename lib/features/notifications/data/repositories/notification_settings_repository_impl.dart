import '../datasources/notification_settings_local_datasource.dart';
import '../../domain/entities/notification_settings.dart';
import '../../domain/repositories/notification_settings_repository.dart';

/// Local-only implementation — notification preferences never sync to the
/// cloud, they are device-specific.
class NotificationSettingsRepositoryImpl
    implements NotificationSettingsRepository {
  final NotificationSettingsLocalDataSource localDataSource;

  const NotificationSettingsRepositoryImpl({required this.localDataSource});

  @override
  NotificationSettings getSettings() => localDataSource.read();

  @override
  Future<void> updateSettings(NotificationSettings settings) =>
      localDataSource.write(settings);
}
