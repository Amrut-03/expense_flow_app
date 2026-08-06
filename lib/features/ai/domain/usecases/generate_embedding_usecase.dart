import 'package:expense_flow_app/features/ai/domain/repositories/embedding_repository.dart';

/// Generates the dense embedding vector for a piece of text.
class GenerateEmbeddingUseCase {
  GenerateEmbeddingUseCase(this._repository);

  final EmbeddingRepository _repository;

  Future<List<double>> call(String text) async {
    return _repository.generateEmbedding(text);
  }
}
