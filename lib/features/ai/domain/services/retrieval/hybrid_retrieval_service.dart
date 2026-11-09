import '../../../../../core/logging/app_log_buffer.dart';
import '../../entities/retrieved_chunk.dart';
import 'lexical_retrieval_service.dart';
import 'retrieval_service.dart';

/// Fuses semantic (vector) and keyword (lexical) rankings with weighted
/// Reciprocal Rank Fusion:
///
/// `score(chunk) = Σ weightᵢ / (k + rankᵢ(chunk))`
///
/// Rank fusion sidesteps the incompatible score scales (cosine similarity
/// vs. IDF coverage). Vectors catch paraphrases ("eating out" → Food), while
/// lexical matching nails exact names the small MiniLM model blurs ("Zepto",
/// "Rapido", "80C").
///
/// Degrades gracefully: when the vector side throws (model asset missing,
/// chunks not embedded yet) the lexical ranking is used on its own, and when
/// neither side matches, the most recent chunks are returned so the model
/// still sees the user's data.
class HybridRetrievalService implements RetrievalService {
  HybridRetrievalService({
    required this.vector,
    required this.lexical,
    this.vectorWeight = 1.0,
    this.lexicalWeight = 1.0,
    this.k = 60,
    this.candidateMultiplier = 3,
  });

  final RetrievalService vector;
  final LexicalRetrievalService lexical;
  final double vectorWeight;
  final double lexicalWeight;

  /// RRF damping constant; 60 is the value from the original RRF paper and
  /// keeps a single first place from dominating.
  final int k;

  /// Each retriever returns `topK × candidateMultiplier` candidates so a
  /// chunk ranked moderately by both sides can still surface.
  final int candidateMultiplier;

  @override
  Future<List<RetrievedChunk>> retrieve({
    required String query,
    int topK = RetrievalService.defaultTopK,
    double minScore = 0.0,
  }) async {
    if (topK < 1) {
      throw ArgumentError.value(topK, 'topK', 'Must be at least 1.');
    }
    if (minScore < -1.0 || minScore > 1.0) {
      throw ArgumentError.value(minScore, 'minScore', 'Must be in [-1, 1].');
    }

    final pool = topK * candidateMultiplier;

    var semantic = const <RetrievedChunk>[];
    try {
      semantic = await vector.retrieve(
        query: query,
        topK: pool,
        minScore: minScore,
      );
    } catch (error, stackTrace) {
      AppLogBuffer.instance.captureError(
        'ai.retrieval.vector',
        error,
        stackTrace,
      );
    }

    final keyword = await lexical.retrieveMatches(
      query: query,
      topK: pool,
      minScore: minScore,
    );

    if (semantic.isEmpty && keyword.isEmpty) {
      return lexical.retrieve(query: query, topK: topK, minScore: minScore);
    }

    return fuse(semantic, keyword, topK: topK);
  }

  /// Weighted RRF over the two rankings. The returned similarity is the
  /// fused score normalised to 0–1 (1 = ranked first by both).
  List<RetrievedChunk> fuse(
    List<RetrievedChunk> semantic,
    List<RetrievedChunk> keyword, {
    required int topK,
  }) {
    final scores = <String, double>{};
    final chunks = <String, RetrievedChunk>{};

    void add(List<RetrievedChunk> ranking, double weight) {
      for (var rank = 0; rank < ranking.length; rank++) {
        final hit = ranking[rank];
        final key = '${hit.chunk.chunkType}|${hit.chunk.sourceId}';
        scores.update(
          key,
          (s) => s + weight / (k + rank + 1),
          ifAbsent: () => weight / (k + rank + 1),
        );
        chunks.putIfAbsent(key, () => hit);
      }
    }

    add(semantic, vectorWeight);
    add(keyword, lexicalWeight);

    final best = (vectorWeight + lexicalWeight) / (k + 1);
    final ordered = scores.keys.toList()
      ..sort((a, b) {
        final byScore = scores[b]!.compareTo(scores[a]!);
        if (byScore != 0) return byScore;
        return chunks[b]!.chunk.updatedAt.compareTo(chunks[a]!.chunk.updatedAt);
      });

    return [
      for (final key in ordered.take(topK))
        RetrievedChunk(
          chunk: chunks[key]!.chunk,
          similarity: (scores[key]! / best).clamp(0.0, 1.0),
        ),
    ];
  }
}
