import '../../entities/retrieved_chunk.dart';

/// Contract for end-to-end retrieval used by [AskQuestionUseCase].
///
/// Implementations turn a natural-language query into the most relevant
/// persisted chunks, ranked by descending relevance and capped at [topK].
///
/// Two implementations exist:
///  * [LexicalRetrievalService] — the temporary production scaffold that
///    ranks by keyword/recency matching over chunk text. Active today.
///  * [VectorRetrievalService] — the semantic, embedding-based retriever.
///    TODO(embedding): make this the primary retrieval strategy once the
///    MiniLM forward pass and model asset are wired up. Swapping only
///    requires changing the DI registration to return this type instead of
///    the lexical one (see `injection_container.dart`).
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
