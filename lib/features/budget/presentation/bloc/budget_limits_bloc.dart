import 'package:dartz/dartz.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:async';
import '../../../../core/error/failures.dart';
import '../../domain/entities/budget_entity.dart';
import '../../domain/usecases/get_budget_limits_usecase.dart';
import '../../domain/usecases/get_budget_periods_usecase.dart';
import '../../domain/usecases/pull_budget_changes_usecase.dart';
import '../../domain/usecases/push_budget_changes_usecase.dart';
import '../../domain/usecases/set_budget_limits_usecase.dart';
import '../../domain/usecases/watch_remote_budgets_usecase.dart';
import 'budget_limits_event.dart';
import 'budget_limits_state.dart';

class BudgetLimitsBloc extends Bloc<BudgetLimitsEvent, BudgetLimitsState> {
  final GetBudgetLimitsUseCase getLimitsUseCase;
  final GetBudgetPeriodsUseCase getPeriodsUseCase;
  final SetBudgetLimitsUseCase setLimitsUseCase;
  final PushBudgetChangesUseCase pushBudgetChangesUseCase;
  final PullBudgetChangesUseCase pullBudgetChangesUseCase;
  final WatchRemoteBudgetsUseCase watchRemoteBudgetsUseCase;
  StreamSubscription<List<BudgetEntity>>? _remoteSubscription;

  BudgetLimitsBloc({
    required this.getLimitsUseCase,
    required this.getPeriodsUseCase,
    required this.setLimitsUseCase,
    required this.pushBudgetChangesUseCase,
    required this.pullBudgetChangesUseCase,
    required this.watchRemoteBudgetsUseCase,
  }) : super(const BudgetLimitsInitial()) {
    on<LoadBudgetLimits>(_onLoad);
    on<SetBudgetLimits>(_onSet);
    on<BudgetRemoteUpdated>(_onRemoteUpdated);

    _remoteSubscription = watchRemoteBudgetsUseCase().listen(
      (_) => add(const BudgetRemoteUpdated()),
      onError: (_) => add(const LoadBudgetLimits()),
    );

    add(const LoadBudgetLimits());
  }

  @override
  Future<void> close() {
    _remoteSubscription?.cancel();
    return super.close();
  }

  Future<void> _onLoad(
    LoadBudgetLimits event,
    Emitter<BudgetLimitsState> emit,
  ) async {
    emit(const BudgetLimitsLoading());

    final message = _failureMessage(await pullBudgetChangesUseCase.call());
    if (message != null) {
      emit(BudgetLimitsError(message));
      return;
    }
    await _emitLoaded(emit);
  }

  Future<void> _onSet(
    SetBudgetLimits event,
    Emitter<BudgetLimitsState> emit,
  ) async {
    emit(const BudgetLimitsLoading());

    await setLimitsUseCase.call(event.limits, periods: event.periods);

    final message = _failureMessage(await pushBudgetChangesUseCase.call());
    if (message != null) {
      emit(BudgetLimitsError(message));
      return;
    }
    await _emitLoaded(emit);
  }

  Future<void> _onRemoteUpdated(
    BudgetRemoteUpdated event,
    Emitter<BudgetLimitsState> emit,
  ) async {
    await _emitLoaded(emit);
  }

  Future<void> _emitLoaded(Emitter<BudgetLimitsState> emit) async {
    final limits = await getLimitsUseCase.call();
    final periods = await getPeriodsUseCase.call();
    emit(BudgetLimitsLoaded(Map.from(limits), periods: Map.from(periods)));
  }

  String? _failureMessage(Either<Failure, void> result) {
    return result.fold(
      (failure) => failure is NetworkFailure ? null : failure.message,
      (_) => null,
    );
  }
}
