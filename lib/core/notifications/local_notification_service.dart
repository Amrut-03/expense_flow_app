import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Android notification channels used across the app. Channels are created once
/// at startup so their importance/priority settings stick.
abstract final class NotificationChannels {
  static const String budgetAlerts = 'budget_alerts';
  static const String reminders = 'reminders';
  static const String summaries = 'summaries';
  static const String general = 'general';
}

/// Thin wrapper around `flutter_local_notifications`.
///
/// Owns initialisation (channels, timezone, tap routing) and exposes a small,
/// app-specific surface: immediate `show`, one-shot `scheduleAt`, repeating
/// `scheduleDaily` and `cancel`. Everything else is hidden from callers.
class LocalNotificationService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  bool get isInitialized => _initialized;

  /// Initialises the plugin, creates channels, sets the local timezone and
  /// wires tap handling. [onTap] receives the notification payload.
  Future<void> initialize({
    required void Function(String? payload) onTap,
  }) async {
    if (_initialized) return;
    _initialized = true;

    await _initTimeZone();

    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@drawable/ic_notification'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );

    await _plugin.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: (response) => onTap(response.payload),
    );

    await _createChannels();

    // App launched from a notification while terminated.
    final launchDetails = await _plugin.getNotificationAppLaunchDetails();
    if (launchDetails?.didNotificationLaunchApp == true) {
      onTap(launchDetails?.notificationResponse?.payload);
    }
  }

  Future<void> requestPermissions() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android != null) {
      await android.requestNotificationsPermission();
    }

    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    if (ios != null) {
      await ios.requestPermissions(alert: true, badge: true, sound: true);
    }
  }

  Future<void> show({
    required int id,
    required String title,
    required String body,
    required String channelId,
    String? payload,
  }) async {
    await _plugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: _details(channelId),
      payload: payload,
    );
  }

  Future<void> scheduleAt({
    required int id,
    required String title,
    required String body,
    required String channelId,
    required tz.TZDateTime date,
    String? payload,
  }) async {
    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: date,
      notificationDetails: _details(channelId),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: payload,
    );
  }

  Future<void> scheduleDaily({
    required int id,
    required String title,
    required String body,
    required String channelId,
    required int hour,
    required int minute,
    String? payload,
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduled,
      notificationDetails: _details(channelId),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: payload,
    );
  }

  Future<void> cancel({required int id}) => _plugin.cancel(id: id);

  Future<void> cancelAll() => _plugin.cancelAll();

  Future<void> _initTimeZone() async {
    tzdata.initializeTimeZones();

    var location = 'Asia/Kolkata';
    try {
      location = (await FlutterTimezone.getLocalTimezone()).identifier;
    } catch (_) {
      // Fall back to a default when the plugin cannot report the device zone.
    }

    tz.setLocalLocation(tz.getLocation(location));
  }

  Future<void> _createChannels() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android == null) return;

    await android.createNotificationChannel(
      const AndroidNotificationChannel(
        NotificationChannels.budgetAlerts,
        'Budget alerts',
        description: 'Alerts when you approach or cross a category budget',
        importance: Importance.high,
      ),
    );
    await android.createNotificationChannel(
      const AndroidNotificationChannel(
        NotificationChannels.reminders,
        'Reminders',
        description: 'Daily expense-logging reminders',
        importance: Importance.defaultImportance,
      ),
    );
    await android.createNotificationChannel(
      const AndroidNotificationChannel(
        NotificationChannels.summaries,
        'Summaries',
        description: 'Weekly and monthly spending summaries',
        importance: Importance.defaultImportance,
      ),
    );
    await android.createNotificationChannel(
      const AndroidNotificationChannel(
        NotificationChannels.general,
        'General',
        description: 'General notifications',
        importance: Importance.defaultImportance,
      ),
    );
  }

  NotificationDetails _details(String channelId) {
    final importance = channelId == NotificationChannels.budgetAlerts
        ? Importance.high
        : Importance.defaultImportance;
    final priority = channelId == NotificationChannels.budgetAlerts
        ? Priority.high
        : Priority.defaultPriority;

    return NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        _channelName(channelId),
        channelDescription: _channelName(channelId),
        icon: 'ic_notification',
        importance: importance,
        priority: priority,
      ),
      iOS: const DarwinNotificationDetails(),
    );
  }

  String _channelName(String channelId) {
    switch (channelId) {
      case NotificationChannels.budgetAlerts:
        return 'Budget alerts';
      case NotificationChannels.reminders:
        return 'Reminders';
      case NotificationChannels.summaries:
        return 'Summaries';
      default:
        return 'General';
    }
  }
}
