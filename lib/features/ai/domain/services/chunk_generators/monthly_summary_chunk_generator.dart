import '../../entities/chunk_inputs.dart';
import 'chunk_generator.dart';
import 'chunk_text_formatter.dart';

/// Generates a natural-language chunk for a monthly spending summary.
///
/// Produces text like:
/// `August 2026: ₹25000 spent across 42 transactions.`
class MonthlySummaryChunkGenerator
    implements ChunkGenerator<MonthlySummaryChunkInput> {
  @override
  String get chunkType => 'monthly_summary';

  @override
  String generate(MonthlySummaryChunkInput input) {
    final month = ChunkTextFormatter.monthYear(input.month);
    final total = ChunkTextFormatter.currency(input.totalSpent);
    final base =
        '$month: $total spent across '
        '${input.transactionCount} '
        '${ChunkTextFormatter.transactions(input.transactionCount)}.';

    final previous = input.previousMonthSpent;
    if (previous == null) {
      return base;
    }

    return '$base (vs ${ChunkTextFormatter.currency(previous)} last month).';
  }
}
