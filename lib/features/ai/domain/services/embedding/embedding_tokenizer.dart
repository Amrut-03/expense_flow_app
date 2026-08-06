import '../../entities/encoded_sequence.dart';

/// Abstract contract for the tokenizer that converts raw text into model
/// input tensors.
///
/// The concrete implementation is a WordPiece tokenizer backed by the
/// bundled `vocab.txt` and shared between training and inference. Keeping it
/// behind an interface keeps the rest of the pipeline model-agnostic.
abstract interface class EmbeddingTokenizer {
  /// Number of entries in the loaded vocabulary.
  int get vocabSize;

  /// Maximum number of tokens the tokenizer produces per input.
  int get maxTokens;

  /// Loads the vocabulary so the tokenizer can encode text.
  ///
  /// Must be called once before [encode]. Implementations should be
  /// idempotent.
  Future<void> load();

  /// Encodes [text] into a fixed-length [EncodedSequence].
  Future<EncodedSequence> encode(String text);
}
