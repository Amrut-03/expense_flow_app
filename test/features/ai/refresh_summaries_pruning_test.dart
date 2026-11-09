import 'package:expense_flow_app/features/ai/domain/entities/embedding_chunk.dart';
import 'package:expense_flow_app/features/ai/domain/repositories/embedding_chunk_repository.dart';
import 'package:expense_flow_app/features/expense/domain/usecases/summary_refresh/refresh_summaries_usecase.dart';
import 'package:expense_flow_app/features/expense/domain/usecases/summary_refresh/summary_chunk_refresher.dart';
import 'package:flutter_test/flutter_test.dart';

class _MemoryChunks implements EmbeddingChunkRepository {
  final Map<String, EmbeddingChunk> byId = {};

  @override
  Future<void> deleteChunk(String id) async => byId.remove(id);
  @override
  Future<List<EmbeddingChunk>> getAllChunks() async => byId.values.toList();
  @override
  Future<void> saveChunk(EmbeddingChunk chunk) async => byId[chunk.id] = chunk;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Goals implements PruningSummaryChunkRefresher {
  _Goals(this.ids);
  final List<String> ids;
  @override
  String get ownedChunkType => 'savings_goal';
  @override
  Future<List<DesiredChunk>> refresh() async => [
    for (final id in ids)
      DesiredChunk(id: id, chunkType: 'savings_goal', text: id, sourceId: id),
  ];
}

EmbeddingChunk stored(String id, String type) {
  final t = DateTime(2026, 11, 1);
  return EmbeddingChunk(
    id: id,
    chunkType: type,
    text: id,
    sourceId: id,
    createdAt: t,
    updatedAt: t,
  );
}

void main() {
  test('pruning refreshers remove their stale chunks only', () async {
    final repo = _MemoryChunks()
      ..byId['goal-old'] = stored('goal-old', 'savings_goal')
      ..byId['goal-keep'] = stored('goal-keep', 'savings_goal')
      ..byId['txn-1'] = stored('txn-1', 'transaction');

    await RefreshSummariesUseCase(
      chunkRepository: repo,
      refreshers: [
        _Goals(['goal-keep', 'goal-new']),
      ],
    )();

    expect(repo.byId.keys, unorderedEquals(['goal-keep', 'goal-new', 'txn-1']));
  });
}
