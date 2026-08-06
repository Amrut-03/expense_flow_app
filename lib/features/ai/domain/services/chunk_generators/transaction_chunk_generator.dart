import '../../entities/chunk_inputs.dart';
import 'chunk_generator.dart';
import 'chunk_text_formatter.dart';

/// Generates a natural-language chunk for a single transaction.
///
/// Produces text like:
/// `₹500 spent on Dominos (Food) on Aug 2.`
class TransactionChunkGenerator
    implements ChunkGenerator<TransactionChunkInput> {
  @override
  String get chunkType => 'transaction';

  @override
  String generate(TransactionChunkInput input) {
    final amount = ChunkTextFormatter.currency(input.amount);
    final date = ChunkTextFormatter.date(input.date);
    final note = (input.note == null || input.note!.isEmpty)
        ? ''
        : ' — ${input.note}';

    return '$amount spent on ${input.merchant} '
        '(${input.categoryName}) on $date.$note';
  }
}
