import '../../entities/embedding_chunk.dart';
import '../../entities/retrieved_chunk.dart';
import '../../repositories/embedding_chunk_repository.dart';
import 'cosine_similarity.dart';

/// Retrieves the top matching chunks for a query embedding.
///
/// Scores stored chunks against the query embedding using cosine similarity,
/// then returns the highest-scoring chunks sorted by similarity (descending).
/// Chunks without an embedding are ignored.
class TopKRetriever {
  TopKRetriever({required this.chunkRepository});

  final EmbeddingChunkRepository chunkRepository;

  /// Scores [chunks] against [queryEmbedding] and returns them sorted by
  /// similarity (descending).
  ///
  /// Chunks without an embedding and results below [minScore] are excluded.
  /// Exposed so higher-level services can compose ranking with additional
  /// tie-breakers and deduplication without repeating the scoring logic.
  List<RetrievedChunk> scoreAll(
    List<double> queryEmbedding,
    Iterable<EmbeddingChunk> chunks, {
    double minScore = 0.0,
  }) {
    return chunks
        .where((chunk) => chunk.embedding.isNotEmpty)
        .map(
          (chunk) => RetrievedChunk(
            chunk: chunk,
            similarity: cosineSimilarity(queryEmbedding, chunk.embedding),
          ),
        )
        .where((result) => result.similarity >= minScore)
        .toList()
      ..sort((a, b) => b.similarity.compareTo(a.similarity));
  }

  /// Returns the top [topK] chunks sorted by similarity to
  /// [queryEmbedding], filtering out results below [minScore].
  ///
  /// Throws an [ArgumentError] when [topK] is less than `1` or [minScore] is
  /// outside the `[-1, 1]` range.
  Future<List<RetrievedChunk>> retrieve({
    required List<double> queryEmbedding,
    int topK = 5,
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

    final chunks = await chunkRepository.getAllChunks();
    final scored = scoreAll(queryEmbedding, chunks, minScore: minScore);

    if (scored.length <= topK) return scored;
    return scored.sublist(0, topK);
  }
}
