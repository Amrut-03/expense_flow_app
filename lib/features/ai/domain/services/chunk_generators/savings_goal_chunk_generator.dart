import '../../entities/chunk_inputs.dart';
import 'chunk_generator.dart';
import 'chunk_text_formatter.dart';

/// Generates a natural-language chunk for a savings goal.
///
/// Produces text like:
/// `Vacation Goal: Saved ₹32000 of ₹70000.`
class SavingsGoalChunkGenerator
    implements ChunkGenerator<SavingsGoalChunkInput> {
  @override
  String get chunkType => 'savings_goal';

  @override
  String generate(SavingsGoalChunkInput input) {
    final saved = ChunkTextFormatter.currency(input.saved);
    final target = ChunkTextFormatter.currency(input.target);
    final targetDate = input.targetDate == null
        ? ''
        : ' Target date: ${ChunkTextFormatter.date(input.targetDate!)}.';

    return '${input.name}: Saved $saved of $target.$targetDate';
  }
}
