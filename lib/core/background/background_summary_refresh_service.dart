import 'package:flutter/foundation.dart';

import '../../features/ai/domain/usecases/embed_pending_chunks_usecase.dart';
import '../../features/expense/domain/usecases/summary_refresh/refresh_summaries_usecase.dart';

/// Runs the summary and embedding refresh outside the UI flow.
///
/// Trigger-agnostic: the same [refresh] entry point is used for the
/// launch-time refresh today and can be invoked by a scheduled worker later
/// without changes to the refresh logic. A failure here must never break the
/// app bootstrap, so errors are captured and logged.
class BackgroundSummaryRefreshService {
  final RefreshSummariesUseCase refreshSummariesUseCase;
  final EmbedPendingChunksUseCase embedPendingChunks;

  const BackgroundSummaryRefreshService({
    required this.refreshSummariesUseCase,
    required this.embedPendingChunks,
  });

  Future<void> refresh() async {
    try {
      await refreshSummariesUseCase();
      if (kDebugMode) {
        debugPrint('[ExpenseFlow] Summary refresh completed.');
      }
    } catch (error, stackTrace) {
      debugPrint('[ExpenseFlow] Summary refresh failed: $error');
      debugPrint(stackTrace.toString());
    }

    try {
      final progress = await embedPendingChunks();
      if (kDebugMode) {
        debugPrint(
          '[ExpenseFlow] Embedding pass completed: '
          '${progress.succeeded} embedded, ${progress.failed} failed, '
          '${progress.total} pending.'
          '${progress.failed > 0 ? ' Failed ids: ${progress.failedChunkIds}' : ''}',
        );
      }
    } catch (error, stackTrace) {
      debugPrint('[ExpenseFlow] Embedding pending chunks failed: $error');
      debugPrint(stackTrace.toString());
    }
  }
}
