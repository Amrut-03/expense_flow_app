import 'package:hive/hive.dart';

import '../../models/embedding_chunk_model.dart';
import 'embedding_chunk_local_datasource.dart';

/// Hive-backed implementation of [EmbeddingChunkLocalDataSource].
///
/// Chunks are stored in a [Box] keyed by [EmbeddingChunkModel.id].
class EmbeddingChunkLocalDataSourceImpl
    implements EmbeddingChunkLocalDataSource {
  final Box<EmbeddingChunkModel> box;

  EmbeddingChunkLocalDataSourceImpl(this.box);

  @override
  Future<void> saveChunk(EmbeddingChunkModel chunk) async {
    await box.put(chunk.id, chunk);
  }

  @override
  Future<void> updateChunk(EmbeddingChunkModel chunk) async {
    await box.put(chunk.id, chunk);
  }

  @override
  Future<void> deleteChunk(String id) async {
    await box.delete(id);
  }

  @override
  Future<List<EmbeddingChunkModel>> getAllChunks() async {
    final chunks = box.values.toList();

    chunks.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return chunks;
  }

  @override
  Future<List<EmbeddingChunkModel>> getChunksNeedingEmbedding() async {
    return box.values.where((chunk) => chunk.needsEmbedding).toList();
  }

  @override
  Future<void> saveEmbedding(String id, List<double> embedding) async {
    final existing = box.get(id);

    if (existing == null) {
      throw StateError('Cannot save embedding: chunk "$id" not found.');
    }

    final updated = existing.copyWith(
      embedding: embedding,
      needsEmbedding: false,
      updatedAt: DateTime.now(),
    );

    await box.put(id, updated);
  }

  @override
  Future<void> clearEmbeddings() async {
    final toReset = box.values
        .where((chunk) => chunk.embedding.isNotEmpty || !chunk.needsEmbedding)
        .toList();

    for (final chunk in toReset) {
      await box.put(
        chunk.id,
        chunk.copyWith(embedding: const [], needsEmbedding: true),
      );
    }
  }
}
