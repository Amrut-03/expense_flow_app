import 'package:expense_flow_app/features/ai/domain/entities/embedding_chunk.dart';
import 'package:expense_flow_app/features/ai/domain/repositories/embedding_chunk_repository.dart';

import 'summary_chunk_refresher.dart';

/// Refreshes the AI summary chunks for a set of summary families.
///
/// Runs every [SummaryChunkRefresher], diffs the result against what is
/// already persisted, and only writes a chunk when its content actually
/// changed. Changed chunks are stored with [EmbeddingChunk.needsEmbedding]
/// set to `true`; untouched chunks keep their existing (possibly embedded)
/// state. A chunk that is missing or new is written with
/// `needsEmbedding: true`.
class RefreshSummariesUseCase {
  final EmbeddingChunkRepository chunkRepository;
  final List<SummaryChunkRefresher> refreshers;

  const RefreshSummariesUseCase({
    required this.chunkRepository,
    required this.refreshers,
  });

  Future<void> call() async {
    final existing = {
      for (final chunk in await chunkRepository.getAllChunks()) chunk.id: chunk,
    };
    final now = DateTime.now();

    for (final refresher in refreshers) {
      final desired = await refresher.refresh();

      for (final chunk in desired) {
        final previous = existing[chunk.id];

        if (previous != null && previous.text == chunk.text) continue;

        await chunkRepository.saveChunk(
          EmbeddingChunk(
            id: chunk.id,
            chunkType: chunk.chunkType,
            text: chunk.text,
            sourceId: chunk.sourceId,
            createdAt: previous?.createdAt ?? now,
            updatedAt: now,
            needsEmbedding: true,
          ),
        );
      }
    }
  }
}
