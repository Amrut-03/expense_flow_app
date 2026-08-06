import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../features/notifications/data/models/app_notification_model.dart';
import '../../features/notifications/domain/entities/app_notification.dart';
import '../../features/notifications/domain/entities/notification_type.dart';
import '../../features/notifications/domain/usecases/save_fcm_token_usecase.dart';
import '../../features/notifications/domain/usecases/save_notification_usecase.dart';
import '../notifications/local_notification_service.dart';
import '../notifications/notification_payload.dart';
import '../router/app_router.dart';

/// Top-level entry point for messages received while the app is terminated or
/// in the background. Runs in a separate isolate, so it cannot rely on GetIt;
/// it only persists to the Hive inbox (best-effort) — the system tray renders
/// notification messages on its own.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  final notification = _notificationFromMessage(message);
  if (notification == null) return;

  try {
    await Hive.initFlutter();
    final box = await Hive.openBox<AppNotificationModel>('notifications_box');
    await box.put(
      notification.id,
      AppNotificationModel.fromEntity(notification),
    );
  } catch (error, stackTrace) {
    debugPrint('[FcmPush] background persist failed: $error');
    debugPrint(stackTrace.toString());
  }
}

/// Wires up Firebase Cloud Messaging for the whole app: permission request,
/// device-token registration, foreground/background/terminated handlers, and
/// in-app routing from the message payload.
class FcmPushService {
  final FirebaseMessaging _messaging;
  final fb.FirebaseAuth _auth;
  final SaveFcmTokenUseCase saveFcmToken;
  final SaveNotificationUseCase saveNotification;
  final LocalNotificationService localNotifications;

  bool _initialized = false;

  FcmPushService(
    this._messaging,
    this._auth, {
    required this.saveFcmToken,
    required this.saveNotification,
    required this.localNotifications,
  });

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    await _messaging.requestPermission(alert: true, badge: true, sound: true);

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    final token = await _messaging.getToken();
    await _saveToken(token);

    _messaging.onTokenRefresh.listen(_saveToken);

    _auth.authStateChanges().listen((user) {
      if (user != null) {
        _messaging.getToken().then(_saveToken);
      }
    });

    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    FirebaseMessaging.onMessageOpenedApp.listen(
      (message) => _handleTap(message, delayNavigation: true),
    );

    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleTap(initialMessage);
    }
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final notification = _notificationFromMessage(message);
    if (notification == null) return;

    await _persistOnly(message);

    // FCM notification messages are not shown automatically while the app is
    // in the foreground — render them through the local notification plugin.
    await localNotifications.show(
      id: (message.messageId ?? notification.id).hashCode & 0x7fffffff,
      title: notification.title,
      body: notification.message,
      channelId: _channelFor(notification.type),
      payload: NotificationPayload(
        type: notification.type,
        title: notification.title,
        message: notification.message,
        emoji: notification.emoji,
        categoryId: notification.categoryId,
      ).encode(),
    );
  }

  String _channelFor(NotificationType type) {
    switch (type) {
      case NotificationType.budgetAlert:
        return NotificationChannels.budgetAlerts;
      case NotificationType.weeklySummary:
      case NotificationType.monthlySummary:
        return NotificationChannels.summaries;
      default:
        return NotificationChannels.general;
    }
  }

  Future<void> _handleTap(
    RemoteMessage message, {
    bool delayNavigation = false,
  }) async {
    await _persistOnly(message);

    final notification = _notificationFromMessage(message);
    if (notification == null) return;

    // Let the UI settle before navigating from a tap on the notification tray.
    if (delayNavigation) {
      await Future<void>.delayed(const Duration(milliseconds: 400));
    }
    AppRouter.router.go(notification.type.defaultRoute);
  }

  Future<void> _persistOnly(RemoteMessage message) async {
    final notification = _notificationFromMessage(message);
    if (notification == null) return;
    await saveNotification(notification);
  }

  Future<void> _saveToken(String? token) async {
    if (token == null || token.isEmpty) return;

    debugPrint('[FcmPush] device token: $token');

    try {
      await saveFcmToken(token);
    } catch (error, stackTrace) {
      // Token registration must never break the app bootstrap; the device is
      // still reachable via the token until Firestore rules permit the write.
      debugPrint('[FcmPush] token save failed: $error');
      debugPrint(stackTrace.toString());
    }
  }
}

AppNotification? _notificationFromMessage(RemoteMessage message) {
  final data = message.data;
  final notificationBody = message.notification;

  final title = data['title'] ?? notificationBody?.title ?? 'ExpenseFlow';
  final body = data['message'] ?? notificationBody?.body ?? '';

  if (title.isEmpty && body.isEmpty) return null;

  final type = NotificationType.fromName(data['type']);
  final id = data['id'] ?? const Uuid().v4();

  return AppNotification(
    id: id,
    type: type,
    title: title,
    message: body,
    emoji: data['emoji'] ?? type.defaultEmoji,
    categoryId: data['categoryId'],
    receivedAt: DateTime.now(),
  );
}
