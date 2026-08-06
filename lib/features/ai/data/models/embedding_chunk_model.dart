import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';

import '../../domain/entities/embedding_chunk.dart';

part 'embedding_chunk_model.g.dart';

/// A persisted text chunk together with its vector embedding.
///
/// [EmbeddingChunkModel] is the Hive-backed storage unit of the AI
/// retrieval module. A chunk represents a small piece of user content
/// (for example a single transaction, a budget note, or a category label)
/// that has been normalised into a single [text] payload and optionally
/// embedded into a numerical [embedding] vector.
///
/// The [needsEmbedding] flag tracks whether the [embedding] still has to
/// be computed by the embedding engine. Chunks that have not been
/// embedded yet keep an empty vector and are flagged for the background
/// indexer so they can be processed in a later pass.
@HiveType(typeId: 3)
class EmbeddingChunkModel extends Equatable {
  /// Stable identifier of this chunk.
  @HiveField(0)
  final String id;

  /// Discriminates the kind of content stored in [text] (for example
  /// `'transaction'`, `'budget'`, or `'category'`).
  @HiveField(1)
  final String chunkType;

  /// Normalised, plain-text content of the chunk.
  ///
  /// This is the text that gets embedded and later retrieved by a
  /// similarity search.
  @HiveField(2)
  final String text;

  /// Dense vector representation of [text].
  ///
  /// Empty until the embedding engine has processed the chunk. The
  /// dimensionality depends on the active embedding model.
  @HiveField(3)
  final List<double> embedding;

  /// Identifier of the source entity this chunk was derived from (for
  /// example the id of a transaction), so results can be traced back.
  @HiveField(4)
  final String sourceId;

  /// Timestamp of when the chunk was first persisted.
  @HiveField(5)
  final DateTime createdAt;

  /// Timestamp of the last modification of the chunk.
  @HiveField(6)
  final DateTime updatedAt;

  /// Whether [embedding] still has to be (re)computed.
  ///
  /// `true` when the chunk was created without a vector or when its
  /// [text] changed and the stored embedding is stale.
  @HiveField(7)
  final bool needsEmbedding;

  const EmbeddingChunkModel({
    required this.id,
    required this.chunkType,
    required this.text,
    this.embedding = const [],
    required this.sourceId,
    required this.createdAt,
    required this.updatedAt,
    this.needsEmbedding = true,
  });

  /// Entity -> Model
  factory EmbeddingChunkModel.fromEntity(EmbeddingChunk entity) {
    return EmbeddingChunkModel(
      id: entity.id,
      chunkType: entity.chunkType,
      text: entity.text,
      embedding: entity.embedding,
      sourceId: entity.sourceId,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      needsEmbedding: entity.needsEmbedding,
    );
  }

  /// JSON -> Model
  factory EmbeddingChunkModel.fromJson(Map<String, dynamic> json) {
    return EmbeddingChunkModel(
      id: json['id'] as String,
      chunkType: json['chunkType'] as String,
      text: json['text'] as String,
      embedding: (json['embedding'] as List<dynamic>? ?? const [])
          .map((e) => (e as num).toDouble())
          .toList(),
      sourceId: json['sourceId'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      needsEmbedding: json['needsEmbedding'] as bool? ?? true,
    );
  }

  /// Model -> JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'chunkType': chunkType,
      'text': text,
      'embedding': embedding,
      'sourceId': sourceId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'needsEmbedding': needsEmbedding,
    };
  }

  /// Model -> Entity
  EmbeddingChunk toEntity() {
    return EmbeddingChunk(
      id: id,
      chunkType: chunkType,
      text: text,
      embedding: embedding,
      sourceId: sourceId,
      createdAt: createdAt,
      updatedAt: updatedAt,
      needsEmbedding: needsEmbedding,
    );
  }

  /// Creates a copy of this chunk with the given fields replaced.
  EmbeddingChunkModel copyWith({
    String? id,
    String? chunkType,
    String? text,
    List<double>? embedding,
    String? sourceId,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? needsEmbedding,
  }) {
    return EmbeddingChunkModel(
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
