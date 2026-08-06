/// Static metadata for the bundled MiniLM sentence-embedding model.
///
/// The values match `sentence-transformers/all-MiniLM-L6-v2`. Update this
/// file when a different MiniLM checkpoint (or quantized variant) is
/// bundled.
abstract final class MiniLmModelConfig {
  /// Asset path of the TensorFlow Lite graph. Expected to be added later.
  static const String modelAssetPath = 'assets/models/minilm/model.tflite';

  /// Asset path of the WordPiece vocabulary. Expected to be added later.
  static const String vocabAssetPath = 'assets/models/minilm/vocab.txt';

  /// Maximum number of tokens accepted per input sequence.
  static const int maxSequenceLength = 128;

  /// Dimensionality of the produced embedding vectors.
  static const int embeddingSize = 384;

  /// WordPiece vocabulary entry for the pad token.
  static const String padToken = '[PAD]';

  /// WordPiece vocabulary entry for the unknown token.
  static const String unknownToken = '[UNK]';

  /// WordPiece vocabulary entry for the classification token.
  static const String clsToken = '[CLS]';

  /// WordPiece vocabulary entry for the separator token.
  static const String sepToken = '[SEP]';
}
