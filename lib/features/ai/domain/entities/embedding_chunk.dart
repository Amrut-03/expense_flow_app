import 'package:equatable/equatable.dart';

/// A text chunk together with its vector embedding.
///
/// [EmbeddingChunk] is the domain representation used by the AI retrieval
/// module. It holds a normalised text payload, an optional dense [embedding]
/// vector, and the [needsEmbedding] flag that tells the indexer whether the
/// vector still has to be computed.
class EmbeddingChunk extends Equatable {
  /// Stable identifier of this chunk.
  final String id;

  /// Discriminates the kind of content stored in [text] (for example
  /// `'transaction'`, `'budget'`, or `'category'`).
  final String chunkType;

  /// Normalised, plain-text content of the chunk.
  final String text;

  /// Dense vector representation of [text]; empty until embedded.
  final List<double> embedding;

  /// Identifier of the source entity this chunk was derived from.
  final String sourceId;

  /// Timestamp of when the chunk was first persisted.
  final DateTime createdAt;

  /// Timestamp of the last modification of the chunk.
  final DateTime updatedAt;

  /// Whether [embedding] still has to be (re)computed.
  final bool needsEmbedding;

  const EmbeddingChunk({
    required this.id,
    required this.chunkType,
    required this.text,
    this.embedding = const [],
    required this.sourceId,
    required this.createdAt,
    required this.updatedAt,
    this.needsEmbedding = true,
  });

  /// Creates a copy of this chunk with the given fields replaced.
  EmbeddingChunk copyWith({
    String? id,
    String? chunkType,
    String? text,
    List<double>? embedding,
    String? sourceId,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? needsEmbedding,
  }) {
    return EmbeddingChunk(
      id: id ?? this.id,
      chunkType: chunkType ?? this.chunkType,
      text: text ?? this.text,
      embedding: embedding ?? this.embedding,
      sourceId: sourceId ?? this.sourceId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      needsEmbedding: needsEmbedding ?? this.needsEmbedding,
    );
  }

  @override
  List<Object?> get props => [
    id,
    chunkType,
    text,
    embedding,
    sourceId,
    createdAt,
    updatedAt,
    needsEmbedding,
  ];
}
