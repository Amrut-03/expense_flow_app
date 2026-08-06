import '../../entities/encoded_sequence.dart';

/// Abstract contract for the sentence-embedding model (MiniLM).
///
/// The concrete implementation wraps the TensorFlow Lite interpreter loaded
/// from the bundled `model.tflite`. Keeping the model behind an interface
/// lets the embedding pipeline depend on an abstraction instead of a
/// concrete TFLite implementation.
abstract interface class EmbeddingModel {
  /// Dimensionality of the produced embedding vectors.
  int get embeddingSize;

  /// Maximum number of tokens the model accepts per input.
  int get maxSequenceLength;

  /// Loads the model graph so it is ready for inference.
  ///
  /// Must be called once before [embed]. Implementations should be
  /// idempotent.
  Future<void> load();

  /// Runs inference for [encodedText] and returns the dense embedding
  /// vector of length [embeddingSize].
  ///
  /// [encodedText] must have been produced by the matching tokenizer.
  Future<List<double>> embed(EncodedSequence encodedText);
}
