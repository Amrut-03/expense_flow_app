import '../../entities/retrieved_chunk.dart';

/// Contract for end-to-end retrieval used by [AskQuestionUseCase].
///
/// Implementations turn a natural-language query into the most relevant
/// persisted chunks, ranked by descending relevance and capped at [topK].
///
/// Implementations:
///  * [FallbackRetrievalService] — the production wiring. Prefers semantic,
///    embedding-based ranking ([VectorRetrievalService]) and automatically
///    degrades to [LexicalRetrievalService] when the on-device embedding
///    model is not available.
///  * [VectorRetrievalService] — the semantic, embedding-based retriever.
///  * [LexicalRetrievalService] — keyword/recency ranking that does not
///    require a working embedding model.
abstract interface class RetrievalService {
  /// Default number of results returned by [AskQuestionUseCase].
  static const int defaultTopK = 8;

  /// Returns up to [topK] chunks most relevant to [query], sorted by
  /// relevance (descending). Results below [minScore] are excluded.
  Future<List<RetrievedChunk>> retrieve({
    required String query,
    int topK = defaultTopK,
    double minScore = 0.0,
  });
}
