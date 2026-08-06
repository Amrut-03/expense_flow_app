import '../services/embedding/embedding_service.dart';

/// Generates an embedding vector for a user query.
///
/// Reuses the app-wide [EmbeddingService] to turn a plain-text question into
/// its dense vector representation. The returned vector can later be compared
/// against chunk vectors for retrieval.
class EmbedQueryUseCase {
  EmbedQueryUseCase({required this.embeddingService});

  final EmbeddingService embeddingService;

  /// Returns the dense embedding vector for [question].
  Future<List<double>> call(String question) {
    return embeddingService.generateEmbedding(question);
  }
}
