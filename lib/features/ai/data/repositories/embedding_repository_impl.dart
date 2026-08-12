import 'package:expense_flow_app/features/ai/domain/repositories/embedding_repository.dart';
import 'package:expense_flow_app/features/ai/domain/services/embedding/embedding_model.dart';
import 'package:expense_flow_app/features/ai/domain/services/embedding/embedding_tokenizer.dart';

/// Default implementation of [EmbeddingRepository].
///
/// Composes the tokenizer and the model into the full embedding pipeline:
/// load assets -> tokenize -> run inference -> return the vector.
class EmbeddingRepositoryImpl implements EmbeddingRepository {
  EmbeddingRepositoryImpl({required this.tokenizer, required this.model});

  final EmbeddingTokenizer tokenizer;
  final EmbeddingModel model;

  bool _isLoaded = false;

  @override
  bool get isLoaded => _isLoaded;

  @override
  int get embeddingSize => model.embeddingSize;

  @override
  Future<void> initialize() async {
    if (_isLoaded) return;

    await tokenizer.load();
    await model.load();
    _isLoaded = true;
  }

  @override
  Future<List<double>> generateEmbedding(String text) async {
    if (!_isLoaded) {
      await initialize();
    }

    final encodedText = await tokenizer.encode(text);

    return model.embed(encodedText);
  }
}
