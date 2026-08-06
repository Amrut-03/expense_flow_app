import 'dart:async';

import '../../domain/entities/app_notification.dart';
import '../../domain/repositories/notification_repository.dart';

/// Streams the notification inbox so the UI stays in sync when pushes arrive
/// while the app is foregrounded or when items are marked read.
class WatchNotificationsUseCase {
  final NotificationRepository repository;

  const WatchNotificationsUseCase(this.repository);

  Stream<List<AppNotification>> call() {
    return repository.watch();
  }
}
