import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/logging/app_log_buffer.dart';
import '../../domain/usecases/get_budget_insights_usecase.dart';

/// Holds the latest [BudgetInsights].
///
/// Refreshed by the app shell whenever expenses or budgets reload, and on
/// its own whenever [changes] fires (recurring rules changed).
class BudgetInsightsCubit extends Cubit<BudgetInsights> {
  BudgetInsightsCubit(this.getInsights, {Stream<void>? changes})
    : super(BudgetInsights.empty) {
    _subscription = changes?.listen((_) => refresh());
  }

  final GetBudgetInsightsUseCase getInsights;
  StreamSubscription<void>? _subscription;

  Future<void> refresh() async {
    try {
      final insights = await getInsights();
      if (!isClosed) emit(insights);
    } catch (e, st) {
      AppLogBuffer.instance.captureError('budgetInsights.refresh', e, st);
    }
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
