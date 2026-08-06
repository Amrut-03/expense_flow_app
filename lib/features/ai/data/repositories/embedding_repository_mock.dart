import 'package:expense_flow_app/features/ai/domain/repositories/embedding_repository.dart';

/// Mock [EmbeddingRepository] that returns a fixed-size zero vector.
///
/// Useful for development and testing when the real MiniLM model assets
/// are not yet available. Returns a 384-dimensional zero vector for any
/// input text. Replace this with [EmbeddingRepositoryImpl] once the
/// model file is bundled and the real pipeline is wired up.
class EmbeddingRepositoryMock implements EmbeddingRepository {
  static const int _embeddingSize = 384;

  @override
  bool get isLoaded => true;

  @override
  int get embeddingSize => _embeddingSize;

  @override
  Future<void> initialize() async {}

  @override
  Future<List<double>> generateEmbedding(String text) async {
    return List<double>.filled(_embeddingSize, 0.0);
  }
}
