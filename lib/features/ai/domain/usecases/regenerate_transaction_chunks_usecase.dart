import '../entities/chunk_inputs.dart';
import '../entities/embedding_chunk.dart';
import '../repositories/embedding_chunk_repository.dart';
import '../services/chunk_generators/category_summary_chunk_generator.dart';
import '../services/chunk_generators/chunk_generator.dart';
import '../services/chunk_generators/monthly_summary_chunk_generator.dart';
import '../services/chunk_generators/transaction_chunk_generator.dart';
import '../services/chunk_generators/weekly_summary_chunk_generator.dart';

/// Regenerates the chunks affected by a single transaction change.
///
/// Persists the transaction's own chunk (or deletes it when the transaction
/// was removed) together with the monthly, weekly, and category summary
/// chunks. All regenerated chunks are stored with
/// [EmbeddingChunk.needsEmbedding] set to `true` so the embedding engine can
/// pick them up later; vectors are left empty until then.
class RegenerateTransactionChunksUseCase {
  /// Prefix used for the chunk id of a single transaction.
  static const String transactionChunkPrefix = 'transaction-';

  final EmbeddingChunkRepository repository;
  final TransactionChunkGenerator transactionChunkGenerator;
  final MonthlySummaryChunkGenerator monthlySummaryChunkGenerator;
  final WeeklySummaryChunkGenerator weeklySummaryChunkGenerator;
  final CategorySummaryChunkGenerator categorySummaryChunkGenerator;

  const RegenerateTransactionChunksUseCase({
    required this.repository,
    required this.transactionChunkGenerator,
    required this.monthlySummaryChunkGenerator,
    required this.weeklySummaryChunkGenerator,
    required this.categorySummaryChunkGenerator,
  });

  Future<void> call(TransactionChunkRegenerationInput input) async {
    final now = DateTime.now();

    final transaction = input.transaction;

    if (transaction == null) {
      await repository.deleteChunk(
        '$transactionChunkPrefix${input.transactionId}',
      );
    } else {
      await repository.saveChunk(
        EmbeddingChunk(
          id: '$transactionChunkPrefix${transaction.id}',
          chunkType: transactionChunkGenerator.chunkType,
          text: transactionChunkGenerator.generate(transaction),
          sourceId: transaction.id,
          createdAt: now,
          updatedAt: now,
        ),
      );
    }

    await repository.saveChunk(
      _summaryChunk(
        id: input.monthlySummary.id,
        generator: monthlySummaryChunkGenerator,
        input: input.monthlySummary,
        now: now,
      ),
    );
    await repository.saveChunk(
      _summaryChunk(
        id: input.weeklySummary.id,
        generator: weeklySummaryChunkGenerator,
        input: input.weeklySummary,
        now: now,
      ),
    );
    await repository.saveChunk(
      _summaryChunk(
        id: input.categorySummary.id,
        generator: categorySummaryChunkGenerator,
        input: input.categorySummary,
        now: now,
      ),
    );
  }

  EmbeddingChunk _summaryChunk<T extends Object>({
    required String id,
    required ChunkGenerator<T> generator,
    required T input,
    required DateTime now,
  }) {
    return EmbeddingChunk(
      id: id,
      chunkType: generator.chunkType,
      text: generator.generate(input),
      sourceId: id,
      createdAt: now,
      updatedAt: now,
    );
  }
}
