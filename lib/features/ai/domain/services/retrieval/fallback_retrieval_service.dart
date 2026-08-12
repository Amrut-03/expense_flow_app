import 'package:flutter/foundation.dart';

import '../../entities/retrieved_chunk.dart';
import 'lexical_retrieval_service.dart';
import 'retrieval_service.dart';
import 'vector_retrieval_service.dart';

/// Retrieval that prefers semantic, embedding-based ranking and degrades to
/// lexical matching when the embedding backend is unavailable or has nothing
/// to offer.
///
/// The MiniLM model is an on-device asset that may not be bundled yet, and
/// stored chunks may not all carry vectors (embedding runs can be in
/// progress or have failed). When [primary] throws (missing model asset,
/// interpreter failure, ...) or returns no results (every chunk still lacks
/// an embedding), the query is routed through [fallback] so the chat
/// pipeline always has context to answer from and the embedding backend
/// failure never surfaces to the user.
class FallbackRetrievalService implements RetrievalService {
  FallbackRetrievalService({required this.primary, required this.fallback});

  final VectorRetrievalService primary;
  final LexicalRetrievalService fallback;

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

    try {
      final results = await primary.retrieve(
        query: query,
        topK: topK,
        minScore: minScore,
      );
      if (results.isNotEmpty) {
        if (kDebugMode) {
          debugPrint(
            '[Retrieval] "$query" -> vector path, '
            '${results.length} result(s).',
          );
        }
        return results;
      }
      if (kDebugMode) {
        debugPrint(
          '[Retrieval] "$query" -> vector path returned no results '
          '(chunks may lack embeddings); falling back to lexical.',
        );
      }
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint(
          '[Retrieval] "$query" -> vector path FAILED: $error',
        );
        debugPrint('$stackTrace');
      }
    }

    final results = await fallback.retrieve(
      query: query,
      topK: topK,
      minScore: minScore,
    );
    if (kDebugMode) {
      debugPrint(
        '[Retrieval] "$query" -> lexical path, ${results.length} result(s).',
      );
    }
    return results;
  }
}
