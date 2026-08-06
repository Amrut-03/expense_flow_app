import '../../models/embedding_chunk_model.dart';

/// Contract for persisting [EmbeddingChunkModel]s in local storage.
///
/// Operates on data-layer models only; the repository layer maps between
/// models and domain entities. The current implementation is backed by
/// Hive.
abstract class EmbeddingChunkLocalDataSource {
  /// Persists [chunk], creating or replacing the entry with the same [id].
  Future<void> saveChunk(EmbeddingChunkModel chunk);

  /// Persists an updated version of an existing [chunk].
  Future<void> updateChunk(EmbeddingChunkModel chunk);

  /// Removes the chunk identified by [id], if present.
  Future<void> deleteChunk(String id);

  /// Returns all stored chunks.
  Future<List<EmbeddingChunkModel>> getAllChunks();

  /// Returns chunks whose [EmbeddingChunkModel.needsEmbedding] is `true`.
  Future<List<EmbeddingChunkModel>> getChunksNeedingEmbedding();

  /// Stores [embedding] for the chunk identified by [id] and marks it as
  /// embedded.
  Future<void> saveEmbedding(String id, List<double> embedding);

  /// Clears every stored embedding vector and marks all chunks as pending
  /// embedding.
  Future<void> clearEmbeddings();
}
