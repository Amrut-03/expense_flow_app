import 'dart:typed_data';

/// Contract for resolving the raw model assets from storage.
///
/// The embedding pipeline uses this to read the TensorFlow Lite graph and
/// the WordPiece vocabulary without knowing where they physically live
/// (currently the Flutter asset bundle).
abstract interface class EmbeddingModelDataSource {
  /// Returns the raw bytes of the TensorFlow Lite model graph.
  Future<Uint8List> loadModelBytes();

  /// Returns the raw WordPiece vocabulary, one token per line.
  Future<String> loadVocabulary();
}
