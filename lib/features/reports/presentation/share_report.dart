import 'package:flutter/widgets.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/logging/app_log_buffer.dart';
import '../../../core/widgets/neu_snack_bar.dart';
import '../../../l10n/app_localizations.dart';
import 'cubit/reports_cubit.dart';

/// Opens the system share sheet for an export, or explains why it couldn't.
Future<void> shareExport(
  BuildContext context,
  ExportResult result, {
  required String subject,
}) async {
  final l10n = AppLocalizations.of(context);
  switch (result) {
    case ExportEmpty():
      NeuSnackBar.show(
        context: context,
        message: l10n.export_nothing,
        type: NeuSnackBarType.info,
      );
    case ExportFailed():
      NeuSnackBar.show(
        context: context,
        message: l10n.export_failed,
        type: NeuSnackBarType.error,
      );
    case ExportReady(:final path):
      try {
        await SharePlus.instance.share(
          ShareParams(files: [XFile(path)], subject: subject),
        );
      } catch (e, st) {
        AppLogBuffer.instance.captureError('reports.share', e, st);
        if (context.mounted) {
          NeuSnackBar.show(
            context: context,
            message: l10n.export_failed,
            type: NeuSnackBarType.error,
          );
        }
      }
  }
}
