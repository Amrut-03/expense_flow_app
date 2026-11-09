import 'package:hive/hive.dart';

import '../../features/insights/domain/usecases/weekly_digest_usecase.dart';
import '../../features/notifications/domain/entities/app_notification.dart';
import '../../features/notifications/domain/entities/notification_type.dart';
import '../../features/notifications/domain/usecases/save_notification_usecase.dart';
import '../logging/app_log_buffer.dart';
import 'notification_scheduler.dart';

/// Refreshes the weekly digest off the startup path: lets the on-device
/// model reword it, re-schedules Monday's notification with the result and
/// drops the digest into the in-app inbox once per week.
class WeeklyDigestService {
  WeeklyDigestService({
    required this.generate,
    required this.scheduler,
    required this.saveNotification,
    required this.stateBox,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  static const _inboxWeekKey = 'weekly_digest_inbox_week';

  final GenerateWeeklyDigestUseCase generate;
  final NotificationScheduler scheduler;
  final SaveNotificationUseCase saveNotification;
  final Box<dynamic> stateBox;
  final DateTime Function() _now;

  Future<void> refresh() async {
    try {
      final digest = await generate();
      await scheduler.scheduleWeeklySummary(digest: digest);
      await _postToInboxOncePerWeek(digest);
    } catch (e, st) {
      AppLogBuffer.instance.captureError('digest.refresh', e, st);
    }
  }

  Future<void> _postToInboxOncePerWeek(WeeklyDigest digest) async {
    final now = _now();
    final week = weekKey(now);
    if (stateBox.get(_inboxWeekKey) == week) return;
    // Skip brand-new users with nothing to summarise yet.
    if (digest.lines.length < 2) return;

    await saveNotification(
      AppNotification(
        id: 'digest_$week',
        type: NotificationType.insight,
        title: 'Your weekly digest',
        message: digest.body,
        emoji: digest.aiWritten ? '✨' : '📊',
        receivedAt: now,
      ),
    );
    await stateBox.put(_inboxWeekKey, week);
  }

  /// Monday-based week key, e.g. `2026-11-02` for the week of Nov 2.
  static String weekKey(DateTime d) {
    final monday = DateTime(d.year, d.month, d.day - (d.weekday - 1));
    return '${monday.year}-${monday.month.toString().padLeft(2, '0')}-'
        '${monday.day.toString().padLeft(2, '0')}';
  }
}
