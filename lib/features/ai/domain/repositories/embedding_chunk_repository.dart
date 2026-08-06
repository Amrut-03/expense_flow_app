import '../entities/embedding_chunk.dart';

/// Contract for persisting and querying [EmbeddingChunk]s.
///
/// Implementations hide the concrete storage (currently Hive). The
/// repository is the single entry point for the AI retrieval storage and
/// keeps storage details out of the domain and presentation layers.
abstract class EmbeddingChunkRepository {
  /// Persists [chunk], creating or replacing the entry with the same [id].
  Future<void> saveChunk(EmbeddingChunk chunk);

  /// Persists an updated version of an existing [chunk].
  Future<void> updateChunk(EmbeddingChunk chunk);

  /// Removes the chunk identified by [id], if present.
  Future<void> deleteChunk(String id);

  /// Returns all stored chunks.
  Future<List<EmbeddingChunk>> getAllChunks();

  /// Returns chunks whose [EmbeddingChunk.needsEmbedding] is `true`.
  Future<List<EmbeddingChunk>> getChunksNeedingEmbedding();

  /// Stores [embedding] for the chunk identified by [id] and marks it as
  /// embedded.
  Future<void> saveEmbedding(String id, List<double> embedding);

  /// Clears every stored embedding vector and marks all chunks as pending
  /// embedding.
  Future<void> clearEmbeddings();
}
