import 'package:flutter/foundation.dart';

import '../../features/expense/domain/usecases/summary_refresh/refresh_summaries_usecase.dart';

/// Runs the summary refresh outside the UI flow.
///
/// Trigger-agnostic: the same [refresh] entry point is used for the
/// launch-time refresh today and can be invoked by a scheduled worker later
/// without changes to the refresh logic. A failure here must never break the
/// app bootstrap, so errors are captured and logged.
class BackgroundSummaryRefreshService {
  final RefreshSummariesUseCase refreshSummariesUseCase;

  const BackgroundSummaryRefreshService({
    required this.refreshSummariesUseCase,
  });

  Future<void> refresh() async {
    try {
      await refreshSummariesUseCase();
    } catch (error, stackTrace) {
      debugPrint('[ExpenseFlow] Summary refresh failed: $error');
      debugPrint(stackTrace.toString());
    }
  }
}
