import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/logging/app_log_buffer.dart';
import '../../../goals/domain/entities/savings_goal.dart';
import '../../../goals/domain/usecases/savings_goal_usecases.dart';
import '../../domain/entities/budget_rollover.dart';
import '../../domain/repositories/budget_rollover_repository.dart';
import '../../domain/usecases/settle_budget_rollover_usecase.dart';

class BudgetRolloverState extends Equatable {
  final Map<String, BudgetRolloverSetting> settings;

  /// Unfinished goals that unspent budget can be moved into.
  final List<SavingsGoal> goals;

  const BudgetRolloverState({this.settings = const {}, this.goals = const []});

  BudgetRolloverSetting settingFor(String categoryId) =>
      settings[categoryId] ?? BudgetRolloverSetting.off;

  @override
  List<Object?> get props => [settings, goals];
}

class BudgetRolloverCubit extends Cubit<BudgetRolloverState> {
  BudgetRolloverCubit({
    required this.repository,
    required this.setRollover,
    required this.getGoals,
  }) : super(BudgetRolloverState(settings: repository.getAll()));

  final BudgetRolloverRepository repository;
  final SetBudgetRolloverUseCase setRollover;
  final GetSavingsGoalsUseCase getGoals;

  Future<void> load() async {
    try {
      final goals = (await getGoals()).where((g) => !g.isComplete).toList();
      if (!isClosed) {
        emit(BudgetRolloverState(settings: repository.getAll(), goals: goals));
      }
    } catch (e, st) {
      AppLogBuffer.instance.captureError('budget.rollover.load', e, st);
    }
  }

  /// Persists every setting in [drafts] that differs from what's stored.
  Future<void> apply(Map<String, BudgetRolloverSetting> drafts) async {
    for (final MapEntry(key: categoryId, value: setting) in drafts.entries) {
      if (state.settingFor(categoryId) == setting) continue;
      await setRollover(categoryId, setting);
    }
    if (!isClosed) {
      emit(
        BudgetRolloverState(settings: repository.getAll(), goals: state.goals),
      );
    }
  }
}
