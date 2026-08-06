import '../../entities/chunk_inputs.dart';
import 'chunk_generator.dart';
import 'chunk_text_formatter.dart';

/// Generates a natural-language chunk for a category budget.
///
/// Produces text like:
/// `Food budget: ₹8200 spent of ₹10000.`
class BudgetChunkGenerator implements ChunkGenerator<BudgetChunkInput> {
  @override
  String get chunkType => 'budget';

  @override
  String generate(BudgetChunkInput input) {
    final period = (input.period.isEmpty || input.period == 'monthly')
        ? ''
        : ' (${input.period})';
    final spent = ChunkTextFormatter.currency(input.spent);
    final limit = ChunkTextFormatter.currency(input.limit);

    return '${input.categoryName} budget$period: '
        '$spent spent of $limit.';
  }
}
