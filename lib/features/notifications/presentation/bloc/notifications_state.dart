import 'package:equatable/equatable.dart';

import '../../domain/entities/app_notification.dart';

sealed class NotificationsState extends Equatable {
  const NotificationsState();

  @override
  List<Object?> get props => [];
}

class NotificationsInitial extends NotificationsState {
  const NotificationsInitial();
}

class NotificationsLoading extends NotificationsState {
  const NotificationsLoading();
}

class NotificationsLoaded extends NotificationsState {
  final List<AppNotification> notifications;

  const NotificationsLoaded(this.notifications);

  @override
  List<Object?> get props => [notifications];

  bool get isEmpty => notifications.isEmpty;

  bool get hasUnread => notifications.any((n) => !n.isRead);

  int get unreadCount => notifications.where((n) => !n.isRead).length;
}
