import '../../entities/chunk_inputs.dart';
import 'chunk_generator.dart';
import 'chunk_text_formatter.dart';

/// Generates a natural-language chunk for a weekly spending summary.
///
/// Produces text like:
/// `Week of Jul 27: ₹4500 spent across 28 transactions.`
class WeeklySummaryChunkGenerator
    implements ChunkGenerator<WeeklySummaryChunkInput> {
  @override
  String get chunkType => 'weekly_summary';

  @override
  String generate(WeeklySummaryChunkInput input) {
    final start = ChunkTextFormatter.date(input.weekStart);
    final total = ChunkTextFormatter.currency(input.totalSpent);
    final base =
        'Week of $start: $total spent across '
        '${input.transactionCount} '
        '${ChunkTextFormatter.transactions(input.transactionCount)}.';

    final previous = input.previousWeekSpent;
    if (previous == null) {
      return base;
    }

    return '$base vs ${ChunkTextFormatter.currency(previous)} last week.';
  }
}
