import 'package:expense_flow_app/features/ai/domain/entities/chunk_inputs.dart';
import 'package:expense_flow_app/features/ai/domain/services/chunk_generators/savings_goal_chunk_generator.dart';
import 'package:expense_flow_app/features/goals/domain/repositories/savings_goal_repository.dart';

import 'summary_chunk_refresher.dart';

/// One `goal-<id>` chunk per savings goal.
class SavingsGoalSummaryRefresher implements PruningSummaryChunkRefresher {
  const SavingsGoalSummaryRefresher({
    required this.repository,
    required this.generator,
  });

  final SavingsGoalRepository repository;
  final SavingsGoalChunkGenerator generator;

  @override
  String get ownedChunkType => generator.chunkType;

  @override
  Future<List<DesiredChunk>> refresh() async {
    return [
      for (final goal in await repository.getAll())
        () {
          final input = SavingsGoalChunkInput(
            id: 'goal-${goal.id}',
            name: goal.name,
            saved: goal.saved,
            target: goal.target,
            targetDate: goal.targetDate,
          );
          return DesiredChunk(
            id: input.id,
            chunkType: generator.chunkType,
            text: generator.generate(input),
            sourceId: input.id,
          );
        }(),
    ];
  }
}
