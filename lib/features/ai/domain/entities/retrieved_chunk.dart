import 'package:equatable/equatable.dart';

import 'embedding_chunk.dart';

/// A chunk returned by retrieval together with its similarity to the query
/// embedding.
class RetrievedChunk extends Equatable {
  /// The matched chunk.
  final EmbeddingChunk chunk;

  /// Cosine similarity between the query embedding and [chunk]'s embedding.
  /// Ranges from `-1.0` to `1.0`.
  final double similarity;

  const RetrievedChunk({required this.chunk, required this.similarity});

  @override
  List<Object?> get props => [chunk, similarity];
}
