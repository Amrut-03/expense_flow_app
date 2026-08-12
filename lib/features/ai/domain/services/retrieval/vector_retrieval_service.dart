import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../../entities/retrieved_chunk.dart';
import '../../repositories/embedding_chunk_repository.dart';
import '../../repositories/embedding_repository.dart';
import 'retrieval_service.dart';
import 'top_k_retriever.dart';

/// Semantic, embedding-based retrieval.
///
/// Embeds the query through the shared [EmbeddingRepository], scores every
/// stored chunk with cosine similarity, breaks ties by recency, deduplicates
/// chunks that share a source entity and chunk type, and returns the top
/// [topK] results.
///
/// This is the preferred retrieval strategy. It is wired as the primary of
/// [FallbackRetrievalService], which routes through the lexical retriever
/// whenever the embedding backend is unavailable (for example while the
/// MiniLM model asset is not bundled).
class VectorRetrievalService implements RetrievalService {
  VectorRetrievalService({
    required this.embeddingRepository,
    required this.topKRetriever,
    required this.chunkRepository,
  });

  final EmbeddingRepository embeddingRepository;
  final TopKRetriever topKRetriever;
  final EmbeddingChunkRepository chunkRepository;

  @override
  Future<List<RetrievedChunk>> retrieve({
    required String query,
    int topK = RetrievalService.defaultTopK,
    double minScore = 0.0,
  }) async {
    if (topK < 1) {
      throw ArgumentError.value(
        topK,
        'topK',
        'Must be greater than or equal to 1.',
      );
    }
    if (minScore < -1.0 || minScore > 1.0) {
      throw ArgumentError.value(
        minScore,
        'minScore',
        'Must be within the range [-1, 1].',
      );
    }

    final queryEmbedding = await embeddingRepository.generateEmbedding(query);
    final chunks = await chunkRepository.getAllChunks();

    if (kDebugMode) {
      final embeddedCount =
          chunks.where((c) => c.embedding.isNotEmpty).length;
      debugPrint(
        '[VectorRetrieval] "$query" embedded=$embeddedCount/${chunks.length}',
      );
      final byType = <String, int>{};
      final embeddedByType = <String, int>{};
      for (final chunk in chunks) {
        byType[chunk.chunkType] = (byType[chunk.chunkType] ?? 0) + 1;
        if (chunk.embedding.isNotEmpty) {
          embeddedByType[chunk.chunkType] =
              (embeddedByType[chunk.chunkType] ?? 0) + 1;
        }
      }
      final breakdown = byType.keys.map(
        (type) => '$type=${byType[type]} '
            '(embedded ${embeddedByType[type] ?? 0})',
      ).join(', ');
      debugPrint('[VectorRetrieval] chunks by type: $breakdown');
      debugPrint(
        '[VectorRetrieval] queryEmbedding dim=${queryEmbedding.length} '
        'head=${queryEmbedding.take(6).map((e) => e.toStringAsFixed(4)).join(', ')} '
        'norm=${_l2Norm(queryEmbedding).toStringAsFixed(4)}',
      );
    }

    final scored = topKRetriever.scoreAll(
      queryEmbedding,
      chunks,
      minScore: minScore,
    );

    scored.sort((a, b) {
      final bySimilarity = b.similarity.compareTo(a.similarity);
      if (bySimilarity != 0) return bySimilarity;
      return b.chunk.createdAt.compareTo(a.chunk.createdAt);
    });

    final deduped = _removeDuplicates(scored);

    final results =
        deduped.length <= topK ? deduped : deduped.sublist(0, topK);

    if (kDebugMode) {
      debugPrint('[VectorRetrieval] top results for "$query":');
      for (var i = 0; i < results.length; i++) {
        final r = results[i];
        debugPrint(
          '  ${i + 1}. id=${r.chunk.id} '
          'sim=${r.similarity.toStringAsFixed(4)} '
          '"${r.chunk.text}"',
        );
      }
    }

    return results;
  }

  double _l2Norm(List<double> vector) {
    var normSquared = 0.0;
    for (final value in vector) {
      normSquared += value * value;
    }
    return math.sqrt(normSquared);
  }

  /// Keeps the highest-ranked instance of each chunk, where a chunk is
  /// identified by its source entity and type (already similarity-sorted).
  List<RetrievedChunk> _removeDuplicates(List<RetrievedChunk> scored) {
    final seenKeys = <String>{};
    final deduped = <RetrievedChunk>[];

    for (final result in scored) {
      final key = '${result.chunk.chunkType}|${result.chunk.sourceId}';
      if (seenKeys.add(key)) {
        deduped.add(result);
      }
    }

    return deduped;
  }
}
