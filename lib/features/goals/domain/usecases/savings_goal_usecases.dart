import 'package:uuid/uuid.dart';

import '../entities/savings_goal.dart';
import '../repositories/savings_goal_repository.dart';

class GoalValidationException implements Exception {
  const GoalValidationException(this.message);
  final String message;
  @override
  String toString() => message;
}

class CreateSavingsGoalUseCase {
  CreateSavingsGoalUseCase(
    this.repository, {
    DateTime Function()? now,
    String Function()? newId,
  }) : _now = now ?? DateTime.now,
       _newId = newId ?? const Uuid().v4;

  static const maxNameLength = 40;

  final SavingsGoalRepository repository;
  final DateTime Function() _now;
  final String Function() _newId;

  Future<SavingsGoal> call({
    required String name,
    required String emoji,
    required double target,
    DateTime? targetDate,
    double initialAmount = 0,
  }) async {
    final trimmed = name.trim();
    final now = _now();
    if (trimmed.isEmpty) {
      throw const GoalValidationException('Goal name is required');
    }
    if (trimmed.length > maxNameLength) {
      throw const GoalValidationException('Goal name is too long');
    }
    if (target <= 0) {
      throw const GoalValidationException('Target must be greater than 0');
    }
    if (initialAmount < 0) {
      throw const GoalValidationException('Amount cannot be negative');
    }
    if (targetDate != null &&
        targetDate.isBefore(DateTime(now.year, now.month, now.day))) {
      throw const GoalValidationException('Target date is in the past');
    }

    final goal = SavingsGoal(
      id: _newId(),
      name: trimmed,
      emoji: emoji,
      target: target,
      targetDate: targetDate,
      contributions: [
        if (initialAmount > 0)
          GoalContribution(amount: initialAmount, date: now),
      ],
      createdAt: now,
      updatedAt: now,
    );
    await repository.save(goal);
    return goal;
  }
}

/// Adds money to a goal ([amount] > 0) or withdraws it ([amount] < 0).
/// A withdrawal can never take the balance below zero.
class AddGoalContributionUseCase {
  AddGoalContributionUseCase(this.repository, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final SavingsGoalRepository repository;
  final DateTime Function() _now;

  Future<SavingsGoal> call(String goalId, double amount) async {
    if (amount == 0) {
      throw const GoalValidationException('Amount must not be 0');
    }
    final goal = await repository.getById(goalId);
    if (goal == null) {
      throw const GoalValidationException('Goal not found');
    }
    if (goal.saved + amount < -0.001) {
      throw const GoalValidationException('Cannot withdraw more than saved');
    }

    final now = _now();
    final updated = goal.copyWith(
      contributions: [
        ...goal.contributions,
        GoalContribution(amount: amount, date: now),
      ],
      updatedAt: now,
    );
    await repository.save(updated);
    return updated;
  }
}

class DeleteSavingsGoalUseCase {
  const DeleteSavingsGoalUseCase(this.repository);
  final SavingsGoalRepository repository;
  Future<void> call(String id) => repository.delete(id);
}

class GetSavingsGoalsUseCase {
  const GetSavingsGoalsUseCase(this.repository);
  final SavingsGoalRepository repository;

  /// Unfinished goals first (soonest deadline first), then completed ones.
  Future<List<SavingsGoal>> call() async {
    final goals = await repository.getAll();
    goals.sort((a, b) {
      if (a.isComplete != b.isComplete) return a.isComplete ? 1 : -1;
      final ad = a.targetDate, bd = b.targetDate;
      if (ad != null && bd != null) return ad.compareTo(bd);
      if (ad != null) return -1;
      if (bd != null) return 1;
      return a.createdAt.compareTo(b.createdAt);
    });
    return goals;
  }
}
