import 'notification_type.dart';

/// A user-facing notification in the in-app inbox.
///
/// Backed by Hive so the list renders instantly and works offline. Derived
/// from an incoming FCM message (see the receive pipeline) but deliberately
/// framework-agnostic to respect the domain layer.
class AppNotification {
  final String id;
  final NotificationType type;
  final String title;
  final String message;
  final String emoji;
  final String? categoryId;
  final DateTime receivedAt;
  final bool isRead;

  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.emoji,
    this.categoryId,
    required this.receivedAt,
    this.isRead = false,
  });

  AppNotification copyWith({
    String? id,
    NotificationType? type,
    String? title,
    String? message,
    String? emoji,
    String? categoryId,
    DateTime? receivedAt,
    bool? isRead,
  }) {
    return AppNotification(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      emoji: emoji ?? this.emoji,
      categoryId: categoryId ?? this.categoryId,
      receivedAt: receivedAt ?? this.receivedAt,
      isRead: isRead ?? this.isRead,
    );
  }
}
