import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/logging/app_log_buffer.dart';
import '../../domain/entities/savings_goal.dart';
import '../../domain/usecases/savings_goal_usecases.dart';

class SavingsGoalsState extends Equatable {
  final bool loading;
  final List<SavingsGoal> goals;

  const SavingsGoalsState({this.loading = true, this.goals = const []});

  @override
  List<Object?> get props => [loading, goals];
}

class SavingsGoalsCubit extends Cubit<SavingsGoalsState> {
  SavingsGoalsCubit({
    required this.getGoals,
    required this.createGoal,
    required this.addContribution,
    required this.deleteGoal,
    Stream<void>? changes,
  }) : super(const SavingsGoalsState()) {
    _subscription = changes?.listen((_) => load());
  }

  final GetSavingsGoalsUseCase getGoals;
  final CreateSavingsGoalUseCase createGoal;
  final AddGoalContributionUseCase addContribution;
  final DeleteSavingsGoalUseCase deleteGoal;
  StreamSubscription<void>? _subscription;

  Future<void> load() async {
    try {
      final goals = await getGoals();
      if (!isClosed) emit(SavingsGoalsState(loading: false, goals: goals));
    } catch (e, st) {
      AppLogBuffer.instance.captureError('goals.load', e, st);
      if (!isClosed) emit(const SavingsGoalsState(loading: false));
    }
  }

  /// Returns an error message, or `null` on success.
  Future<String?> create({
    required String name,
    required String emoji,
    required double target,
    DateTime? targetDate,
    double initialAmount = 0,
  }) async {
    try {
      await createGoal(
        name: name,
        emoji: emoji,
        target: target,
        targetDate: targetDate,
        initialAmount: initialAmount,
      );
      return null;
    } on GoalValidationException catch (e) {
      return e.message;
    }
  }

  /// Returns an error message, or `null` on success.
  Future<String?> contribute(String goalId, double amount) async {
    try {
      await addContribution(goalId, amount);
      return null;
    } on GoalValidationException catch (e) {
      return e.message;
    }
  }

  Future<void> delete(String goalId) => deleteGoal(goalId);

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
