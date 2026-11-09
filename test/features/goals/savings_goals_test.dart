import 'dart:async';

import 'package:expense_flow_app/features/goals/domain/entities/savings_goal.dart';
import 'package:expense_flow_app/features/goals/domain/repositories/savings_goal_repository.dart';
import 'package:expense_flow_app/features/goals/domain/services/goal_progress.dart';
import 'package:expense_flow_app/features/goals/domain/usecases/savings_goal_usecases.dart';
import 'package:flutter_test/flutter_test.dart';

class _MemoryGoals implements SavingsGoalRepository {
  final Map<String, SavingsGoal> byId = {};
  @override
  Future<void> delete(String id) async => byId.remove(id);
  @override
  Future<List<SavingsGoal>> getAll() async => byId.values.toList();
  @override
  Future<SavingsGoal?> getById(String id) async => byId[id];
  @override
  Future<void> save(SavingsGoal goal) async => byId[goal.id] = goal;
  @override
  Stream<void> watch() => const Stream.empty();
}

void main() {
  final created = DateTime(2026, 11, 1);
  late _MemoryGoals repo;
  late DateTime now;

  setUp(() {
    repo = _MemoryGoals();
    now = created;
  });

  CreateSavingsGoalUseCase create() =>
      CreateSavingsGoalUseCase(repo, now: () => now, newId: () => 'g1');
  AddGoalContributionUseCase contribute() =>
      AddGoalContributionUseCase(repo, now: () => now);

  group('use cases', () {
    test('creates a goal with an optional starting amount', () async {
      final goal = await create()(
        name: ' Goa trip ',
        emoji: '🏖️',
        target: 30000,
        targetDate: DateTime(2027, 1, 30),
        initialAmount: 5000,
      );
      expect(goal.name, 'Goa trip');
      expect(goal.saved, 5000);
      expect(repo.byId['g1'], goal);
    });

    test('validates name, target, amount and date', () async {
      Future<void> bad(Future<void> Function() f) =>
          expectLater(f(), throwsA(isA<GoalValidationException>()));

      await bad(() => create()(name: ' ', emoji: '🎯', target: 100));
      await bad(() => create()(name: 'x' * 41, emoji: '🎯', target: 100));
      await bad(() => create()(name: 'A', emoji: '🎯', target: 0));
      await bad(
        () => create()(name: 'A', emoji: '🎯', target: 10, initialAmount: -1),
      );
      await bad(
        () => create()(
          name: 'A',
          emoji: '🎯',
          target: 10,
          targetDate: DateTime(2026, 10, 31),
        ),
      );
    });

    test('deposits and withdrawals, never below zero', () async {
      await create()(name: 'Phone', emoji: '📱', target: 20000);
      await contribute()('g1', 3000);
      final afterWithdraw = await contribute()('g1', -1000);
      expect(afterWithdraw.saved, 2000);

      await expectLater(
        contribute()('g1', -2500),
        throwsA(isA<GoalValidationException>()),
      );
      await expectLater(
        contribute()('g1', 0),
        throwsA(isA<GoalValidationException>()),
      );
    });

    test('lists unfinished goals first, soonest deadline first', () async {
      SavingsGoal goal(String id, {DateTime? by, double saved = 0}) =>
          SavingsGoal(
            id: id,
            name: id,
            emoji: '🎯',
            target: 100,
            targetDate: by,
            contributions: [
              if (saved > 0) GoalContribution(amount: saved, date: created),
            ],
            createdAt: created,
            updatedAt: created,
          );
      await repo.save(goal('done', saved: 100));
      await repo.save(goal('later', by: DateTime(2027, 6)));
      await repo.save(goal('soon', by: DateTime(2026, 12)));
      await repo.save(goal('open'));

      final ordered = await GetSavingsGoalsUseCase(repo)();
      expect(ordered.map((g) => g.id), ['soon', 'later', 'open', 'done']);
    });
  });

  group('GoalProgress', () {
    SavingsGoal goal({double saved = 0, DateTime? by}) => SavingsGoal(
      id: 'g',
      name: 'g',
      emoji: '🎯',
      target: 3000,
      targetDate: by,
      contributions: [
        if (saved > 0) GoalContribution(amount: saved, date: created),
      ],
      createdAt: created,
      updatedAt: created,
    );

    test('per-day target and on-track status', () {
      // 30-day goal created Nov 1, due Nov 30. On Nov 16, 15 days left.
      final p = GoalProgress.of(
        goal(saved: 1600, by: DateTime(2026, 11, 30)),
        DateTime(2026, 11, 16),
      );
      expect(p.daysLeft, 15);
      expect(p.perDay, closeTo(1400 / 15, 1e-9));
      expect(p.pace, GoalPace.onTrack);
      expect(p.percent, closeTo(53.33, 0.01));
    });

    test('behind schedule', () {
      final p = GoalProgress.of(
        goal(saved: 200, by: DateTime(2026, 11, 30)),
        DateTime(2026, 11, 20),
      );
      expect(p.pace, GoalPace.behind);
    });

    test('complete, overdue and no-deadline states', () {
      expect(
        GoalProgress.of(goal(saved: 3000), created).pace,
        GoalPace.complete,
      );
      expect(
        GoalProgress.of(
          goal(by: DateTime(2026, 11, 5)),
          DateTime(2026, 11, 6),
        ).pace,
        GoalPace.overdue,
      );
      final open = GoalProgress.of(goal(saved: 500), created);
      expect(open.pace, GoalPace.noDeadline);
      expect(open.remaining, 2500);
    });

    test('JSON round trip', () {
      final g = goal(saved: 750, by: DateTime(2027, 1, 1));
      expect(SavingsGoal.fromMap(g.toMap()), g);
    });
  });
}
