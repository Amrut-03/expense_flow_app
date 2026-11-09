import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/category_label.dart';
import '../../../core/notifications/amount_formatter.dart';
import '../../../core/notifications/capture_notification_service.dart';
import '../../../core/widgets/neu_snack_bar.dart';
import '../../../l10n/app_localizations.dart';
import '../../expense/domain/validation/expense_validator.dart';
import '../../expense/presentation/bloc/expense_bloc.dart';
import '../domain/entities/captured_transaction.dart';
import '../domain/repositories/sms_capture_repository.dart';
import 'capture_expense_event.dart';
import 'cubit/sms_capture_cubit.dart';

/// Handles the [OK] / [Change] buttons on "payment detected" notifications.
///
/// Runs inside the app (actions use `showsUserInterface`), so OK goes
/// through the same [ExpenseBloc] as the review screen: identical sync and
/// AI-chunk refresh.
class CaptureNotificationActionHandler {
  const CaptureNotificationActionHandler(this.repository);

  final SmsCaptureRepository repository;

  /// [context] must sit below the app's bloc providers.
  Future<void> handle(
    BuildContext context, {
    required String actionId,
    required String captureId,
  }) async {
    final capture = repository
        .getAll()
        .where((c) => c.id == captureId)
        .firstOrNull;

    final canAccept =
        actionId == CaptureNotificationActions.accept &&
        capture != null &&
        capture.status == CaptureStatus.pending &&
        capture.suggestedCategoryId != null &&
        capture.amount <= ExpenseValidator.maxAmount;

    if (!canAccept) {
      // Change/Review, or OK on something that needs a human look.
      if (capture == null || capture.status == CaptureStatus.pending) {
        GoRouter.of(context).go('/captures');
      }
      return;
    }

    final l10n = AppLocalizations.of(context);
    final category = capture.suggestedCategoryId!;
    context.read<ExpenseBloc>().add(
      captureToExpenseEvent(
        capture,
        categoryId: category,
        fallbackTitle: l10n.capture_defaultTitle,
      ),
    );
    await context.read<SmsCaptureCubit>().markResolved(capture, accepted: true);

    if (context.mounted) {
      NeuSnackBar.show(
        context: context,
        message: l10n.capture_loggedFromNotification(
          formatInr(capture.amount),
          CategoryLabels.labelOf(category),
        ),
        type: NeuSnackBarType.success,
      );
    }
  }
}
