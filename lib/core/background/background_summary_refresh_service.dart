import '../../features/ai/domain/usecases/embed_pending_chunks_usecase.dart';
import '../../features/expense/domain/usecases/summary_refresh/refresh_summaries_usecase.dart';
import '../logging/app_log_buffer.dart';

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
    } catch (error, stackTrace) {
      AppLogBuffer.instance.captureError(
        'background.summaryRefresh',
        error,
        stackTrace,
      );
    }

    try {
      await embedPendingChunks();
    } catch (error, stackTrace) {
      AppLogBuffer.instance.captureError(
        'background.embedPending',
        error,
        stackTrace,
      );
    }
  }
}
