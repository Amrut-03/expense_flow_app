import 'dart:convert';

import '../../features/notifications/domain/entities/notification_type.dart';

/// A consistent, JSON-serialisable payload attached to local notifications.
///
/// Mirrors the `data` shape used by the FCM receive pipeline so routing and
/// the in-app inbox behave identically for local and remote messages.
class NotificationPayload {
  const NotificationPayload({
    required this.type,
    required this.title,
    required this.message,
    this.emoji,
    this.categoryId,
  });

  final NotificationType type;
  final String title;
  final String message;
  final String? emoji;
  final String? categoryId;

  Map<String, String> toJson() {
    return {
      'type': type.fcmName,
      'title': title,
      'message': message,
      'emoji': emoji ?? type.defaultEmoji,
      'categoryId': ?categoryId,
    };
  }

  String encode() => jsonEncode(toJson());

  static NotificationPayload? decode(String? raw) {
    if (raw == null || raw.isEmpty) return null;

    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      return NotificationPayload(
        type: NotificationType.fromName(data['type'] as String?),
        title: data['title'] as String? ?? 'ExpenseFlow',
        message: data['message'] as String? ?? '',
        emoji: data['emoji'] as String?,
        categoryId: data['categoryId'] as String?,
      );
    } catch (_) {
      return null;
    }
  }

  /// Extracts the routing target from a notification payload, defaulting to a
  /// safe route when the payload is absent or malformed.
  static NotificationType typeFrom(String? raw) {
    return decode(raw)?.type ?? NotificationType.general;
  }
}
