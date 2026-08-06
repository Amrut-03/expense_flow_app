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
/// This was the original (and future) retrieval strategy. It is currently
/// superseded by [LexicalRetrievalService] because the MiniLM embedding
/// forward pass and its model asset are not wired up yet.
/// TODO(embedding): make this the primary strategy once embeddings work; the
/// rest of the pipeline already targets the [RetrievalService] contract.
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

    if (deduped.length <= topK) return deduped;
    return deduped.sublist(0, topK);
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
