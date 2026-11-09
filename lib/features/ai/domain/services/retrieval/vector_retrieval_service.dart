import '../../entities/embedding_chunk.dart';
import '../../entities/retrieved_chunk.dart';
import '../../repositories/embedding_chunk_repository.dart';
import '../../repositories/embedding_repository.dart';
import 'retrieval_service.dart';
import 'top_k_retriever.dart';
import 'vector_index_cache.dart';

/// Semantic, embedding-based retrieval.
///
/// Embeds the query through the shared [EmbeddingRepository], scores every
/// stored chunk with cosine similarity, breaks ties by recency, deduplicates
/// chunks that share a source entity and chunk type, and returns the top
/// [topK] results.
///
/// Wired as the semantic half of [HybridRetrievalService], which fuses it
/// with lexical ranking and carries on lexically when the embedding backend
/// is unavailable.
class VectorRetrievalService implements RetrievalService {
  VectorRetrievalService({
    required this.embeddingRepository,
    required this.topKRetriever,
    required this.chunkRepository,
    this.indexCache,
  });

  final EmbeddingRepository embeddingRepository;
  final TopKRetriever topKRetriever;
  final EmbeddingChunkRepository chunkRepository;

  /// Quantised (and, for large stores, IVF-partitioned) index. When `null`
  /// every query brute-forces all chunks.
  final VectorIndexCache? indexCache;

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

    final cache = indexCache;
    final scored = cache != null
        ? await cache.search(
            queryEmbedding,
            chunks,
            limit: topK,
            minScore: minScore,
          )
        : _bruteForce(queryEmbedding, chunks, minScore);

    final deduped = _removeDuplicates(scored);

    final results = deduped.length <= topK ? deduped : deduped.sublist(0, topK);

    return results;
  }

  List<RetrievedChunk> _bruteForce(
    List<double> queryEmbedding,
    List<EmbeddingChunk> chunks,
    double minScore,
  ) {
    return topKRetriever.scoreAll(queryEmbedding, chunks, minScore: minScore)
      ..sort((a, b) {
        final bySimilarity = b.similarity.compareTo(a.similarity);
        if (bySimilarity != 0) return bySimilarity;
        return b.chunk.createdAt.compareTo(a.chunk.createdAt);
      });
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
