import 'package:expense_flow_app/features/ai/domain/repositories/embedding_repository.dart';

/// App-wide facade for sentence embedding generation.
///
/// [EmbeddingService] is the single entry point for producing vector
/// embeddings from text using the bundled MiniLM model. It is a lazily
/// created singleton: call [configure] once during startup (usually from
/// service locator registration) and then access it via [instance].
class EmbeddingService {
  EmbeddingService._(this._repository);

  final EmbeddingRepository _repository;

  static EmbeddingService? _instance;

  /// The single app-wide instance.
  ///
  /// Throws a [StateError] if [configure] has not been called yet.
  static EmbeddingService get instance {
    final service = _instance;
    if (service == null) {
      throw StateError(
        'EmbeddingService.configure() must be called before accessing '
        'EmbeddingService.instance.',
      );
    }
    return service;
  }

  /// Registers [repository] as the backing implementation for the service
  /// and returns the (idempotent) singleton instance.
  static EmbeddingService configure(EmbeddingRepository repository) {
    return _instance ??= EmbeddingService._(repository);
  }

  /// Whether the tokenizer and model have been loaded.
  bool get isLoaded => _repository.isLoaded;

  /// Dimensionality of the produced embedding vectors.
  int get embeddingSize => _repository.embeddingSize;

  /// Loads the MiniLM model and tokenizer. Safe to call repeatedly.
  Future<void> initialize() => _repository.initialize();

  /// Generates the dense embedding vector for [text].
  Future<List<double>> generateEmbedding(String text) =>
      _repository.generateEmbedding(text);
}
