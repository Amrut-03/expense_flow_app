import '../../domain/entities/embedding_chunk.dart';
import '../../domain/repositories/embedding_chunk_repository.dart';
import '../datasources/local/embedding_chunk_local_datasource.dart';
import '../models/embedding_chunk_model.dart';

class EmbeddingChunkRepositoryImpl implements EmbeddingChunkRepository {
  final EmbeddingChunkLocalDataSource localDataSource;

  EmbeddingChunkRepositoryImpl({required this.localDataSource});

  @override
  Future<void> saveChunk(EmbeddingChunk chunk) async {
    final model = EmbeddingChunkModel.fromEntity(chunk);

    await localDataSource.saveChunk(model);
  }

  @override
  Future<void> updateChunk(EmbeddingChunk chunk) async {
    final model = EmbeddingChunkModel.fromEntity(chunk);

    await localDataSource.updateChunk(model);
  }

  @override
  Future<void> deleteChunk(String id) async {
    await localDataSource.deleteChunk(id);
  }

  @override
  Future<List<EmbeddingChunk>> getAllChunks() async {
    final models = await localDataSource.getAllChunks();

    return models.map((model) => model.toEntity()).toList();
  }

  @override
  Future<List<EmbeddingChunk>> getChunksNeedingEmbedding() async {
    final models = await localDataSource.getChunksNeedingEmbedding();

    return models.map((model) => model.toEntity()).toList();
  }

  @override
  Future<void> saveEmbedding(String id, List<double> embedding) async {
    await localDataSource.saveEmbedding(id, embedding);
  }

  @override
  Future<void> clearEmbeddings() async {
    await localDataSource.clearEmbeddings();
  }
}
