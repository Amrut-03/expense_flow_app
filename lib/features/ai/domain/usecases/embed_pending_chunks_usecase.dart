import 'package:flutter/foundation.dart';

import '../entities/embedding_progress.dart';
import '../repositories/embedding_chunk_repository.dart';
import '../repositories/embedding_repository.dart';

/// Reports the state of an embedding pipeline run.
typedef EmbeddingProgressCallback = void Function(EmbeddingProgress progress);

/// Drains the pending embedding queue.
///
/// Loads every chunk with `needsEmbedding == true`, generates its embedding
/// through [EmbeddingRepository], and persists the vector with
/// [EmbeddingChunkRepository.saveEmbedding], which also flips
/// `needsEmbedding` to `false`. Processing continues until the initial queue
/// snapshot is exhausted.
///
/// Failure handling: the run aborts only if the model cannot be initialised.
/// Individual chunks that fail to embed are skipped without aborting the run,
/// are reported through [EmbeddingProgress.failedChunkIds], and keep
/// `needsEmbedding == true` so a later invocation retries them.
class EmbedPendingChunksUseCase {
  EmbedPendingChunksUseCase({
    required this.chunkRepository,
    required this.embeddingRepository,
  });

  final EmbeddingChunkRepository chunkRepository;
  final EmbeddingRepository embeddingRepository;

  /// Runs one embedding pass and returns the final [EmbeddingProgress].
  ///
  /// [onProgress] is invoked after every processed chunk and once more with
  /// the completed run.
  Future<EmbeddingProgress> call({
    EmbeddingProgressCallback? onProgress,
  }) async {
    await embeddingRepository.initialize();

    final pending = await chunkRepository.getChunksNeedingEmbedding();
    final total = pending.length;

    if (kDebugMode) {
      debugPrint('[EmbedChunks] run started; $total chunk(s) need embedding.');
    }

    var processed = 0;
    var succeeded = 0;
    var failed = 0;
    final failedChunkIds = <String>[];

    EmbeddingProgress build({bool isCompleted = false}) => EmbeddingProgress(
      total: total,
      processed: processed,
      succeeded: succeeded,
      failed: failed,
      isCompleted: isCompleted,
      failedChunkIds: List.unmodifiable(failedChunkIds),
    );

    for (final chunk in pending) {
      try {
        final embedding = await embeddingRepository.generateEmbedding(
          chunk.text,
        );

        await chunkRepository.saveEmbedding(chunk.id, embedding);
        succeeded++;
      } catch (error, stackTrace) {
        failed++;
        failedChunkIds.add(chunk.id);
        if (kDebugMode) {
          debugPrint(
            '[EmbedChunks] failed to embed id=${chunk.id} '
            '"${chunk.text}": $error',
          );
          debugPrint('$stackTrace');
        }
      }

      processed++;
      onProgress?.call(build());
    }

    if (kDebugMode) {
      debugPrint(
        '[EmbedChunks] run finished: $succeeded succeeded, $failed failed '
        'of $total.',
      );
    }

    final completed = build(isCompleted: true);
    onProgress?.call(completed);

    return completed;
  }
}
