import '../../features/notifications/domain/entities/notification_type.dart';
import '../../features/notifications/domain/repositories/notification_settings_repository.dart';
import '../../features/sms_capture/domain/entities/captured_transaction.dart';
import '../../features/sms_capture/domain/repositories/sms_capture_repository.dart';
import '../constants/category_label.dart';
import 'amount_formatter.dart';
import 'local_notification_service.dart';
import 'notification_payload.dart';

/// Action ids carried by "payment detected" notifications.
abstract final class CaptureNotificationActions {
  /// Log the payment with the suggested category.
  static const accept = 'capture_accept';

  /// Open the review queue to pick another category or dismiss.
  static const change = 'capture_change';
}

/// Posts "₹120 at Swiggy — add as Food? [OK] [Change]" for new SMS captures.
class CaptureNotificationService implements CaptureNotifier {
  CaptureNotificationService({
    required this.notifications,
    required this.settingsRepository,
  });

  /// More than this many at once collapse into one summary notification.
  static const maxIndividual = 3;

  static const _summaryId = 3999;
  static const _idBase = 3000;

  final LocalNotificationService notifications;
  final NotificationSettingsRepository settingsRepository;

  /// Stable per capture, so a re-post replaces rather than stacks.
  static int idFor(String captureId) =>
      _idBase + (captureId.hashCode & 0x7fffffff) % 999;

  @override
  Future<void> notify(List<CapturedTransaction> captures) async {
    if (captures.isEmpty || !notifications.isInitialized) return;
    if (!settingsRepository.getSettings().captureAlertsEnabled) return;

    if (captures.length > maxIndividual) {
      final total = captures.fold<double>(0, (s, c) => s + c.amount);
      const title = 'New payments detected';
      final body =
          '${captures.length} payments (${formatInr(total)}) from your bank '
          'SMS are ready to review.';
      await notifications.show(
        id: _summaryId,
        title: title,
        body: body,
        channelId: NotificationChannels.general,
        payload: const NotificationPayload(
          type: NotificationType.transactionCaptured,
          title: title,
          message: '',
        ).encode(),
      );
      return;
    }

    for (final c in captures) {
      final category = c.suggestedCategoryId;
      final where = c.merchant == null ? '' : ' at ${c.merchant}';
      final title = '${formatInr(c.amount)}$where';
      final body = category == null
          ? 'Detected from your bank SMS. Tap to review.'
          : 'Add as ${CategoryLabels.labelOf(category)}?';

      await notifications.show(
        id: idFor(c.id),
        title: title,
        body: body,
        channelId: NotificationChannels.general,
        payload: NotificationPayload(
          type: NotificationType.transactionCaptured,
          title: title,
          message: body,
          categoryId: category,
          refId: c.id,
        ).encode(),
        actions: [
          if (category != null)
            const NotificationAction(CaptureNotificationActions.accept, 'OK'),
          NotificationAction(
            CaptureNotificationActions.change,
            category == null ? 'Review' : 'Change',
          ),
        ],
      );
    }
  }
}
