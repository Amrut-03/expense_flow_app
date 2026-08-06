import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/clear_notifications_usecase.dart';
import '../../domain/usecases/mark_all_notifications_read_usecase.dart';
import '../../domain/usecases/mark_notification_read_usecase.dart';
import '../../domain/usecases/watch_notifications_usecase.dart';
import 'notifications_state.dart';

/// Streams the in-app notification inbox and exposes read/clear actions.
class NotificationsCubit extends Cubit<NotificationsState> {
  final WatchNotificationsUseCase watchNotifications;
  final MarkNotificationReadUseCase markRead;
  final MarkAllNotificationsReadUseCase markAllRead;
  final ClearNotificationsUseCase clear;

  StreamSubscription? _subscription;

  NotificationsCubit({
    required this.watchNotifications,
    required this.markRead,
    required this.markAllRead,
    required this.clear,
  }) : super(const NotificationsInitial());

  Future<void> load() async {
    await _subscription?.cancel();

    emit(const NotificationsLoading());

    _subscription = watchNotifications().listen(
      (notifications) => emit(NotificationsLoaded(notifications)),
      onError: (_) => emit(const NotificationsLoaded([])),
    );
  }

  Future<void> markNotificationRead(String id) async {
    await markRead(id);
  }

  Future<void> markAllAsRead() async {
    await markAllRead();
  }

  Future<void> clearAll() async {
    await clear();
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
