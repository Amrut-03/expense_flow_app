/// Contract for the embedding generation pipeline.
///
/// Owns the lifecycle (load) and the text -> vector transformation. The
/// repository hides whether the model runs on-device via TensorFlow Lite,
/// which tokenizer is used, and how the model assets are resolved.
abstract interface class EmbeddingRepository {
  /// Whether the model and tokenizer have been loaded.
  bool get isLoaded;

  /// Dimensionality of the produced embedding vectors.
  int get embeddingSize;

  /// Loads the tokenizer vocabulary and the model graph.
  ///
  /// Safe to call multiple times; subsequent calls are no-ops.
  Future<void> initialize();

  /// Generates the dense embedding vector for [text].
  ///
  /// Lazily initializes the pipeline on first use.
  Future<List<double>> generateEmbedding(String text);
}
