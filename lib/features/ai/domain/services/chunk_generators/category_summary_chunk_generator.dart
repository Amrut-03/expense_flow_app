import '../../entities/chunk_inputs.dart';
import 'chunk_generator.dart';
import 'chunk_text_formatter.dart';

/// Generates a natural-language chunk for a category spending summary.
///
/// Produces text like:
/// `Food: ₹8200 spent across 12 transactions from Jul 1 to Jul 31.`
class CategorySummaryChunkGenerator
    implements ChunkGenerator<CategorySummaryChunkInput> {
  @override
  String get chunkType => 'category_summary';

  @override
  String generate(CategorySummaryChunkInput input) {
    final total = ChunkTextFormatter.currency(input.totalSpent);
    final start = ChunkTextFormatter.date(input.periodStart);
    final end = ChunkTextFormatter.date(input.periodEnd);

    return '${input.categoryName}: $total spent across '
        '${input.transactionCount} '
        '${ChunkTextFormatter.transactions(input.transactionCount)} '
        'from $start to $end.';
  }
}
