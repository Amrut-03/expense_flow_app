import 'package:hive/hive.dart';

import '../../domain/entities/app_notification.dart';
import '../../domain/entities/notification_type.dart';

part 'app_notification_model.g.dart';

@HiveType(typeId: 4)
class AppNotificationModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String type;

  @HiveField(2)
  final String title;

  @HiveField(3)
  final String message;

  @HiveField(4)
  final String emoji;

  @HiveField(5)
  final String? categoryId;

  @HiveField(6)
  final DateTime receivedAt;

  @HiveField(7)
  final bool isRead;

  AppNotificationModel({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.emoji,
    this.categoryId,
    required this.receivedAt,
    this.isRead = false,
  });

  factory AppNotificationModel.fromEntity(AppNotification entity) {
    return AppNotificationModel(
      id: entity.id,
      type: entity.type.fcmName,
      title: entity.title,
      message: entity.message,
      emoji: entity.emoji,
      categoryId: entity.categoryId,
      receivedAt: entity.receivedAt,
      isRead: entity.isRead,
    );
  }

  AppNotification toEntity() {
    return AppNotification(
      id: id,
      type: NotificationType.fromName(type),
      title: title,
      message: message,
      emoji: emoji,
      categoryId: categoryId,
      receivedAt: receivedAt,
      isRead: isRead,
    );
  }

  AppNotificationModel copyWith({bool? isRead}) {
    return AppNotificationModel(
      id: id,
      type: type,
      title: title,
      message: message,
      emoji: emoji,
      categoryId: categoryId,
      receivedAt: receivedAt,
      isRead: isRead ?? this.isRead,
    );
  }
}
