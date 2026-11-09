import 'dart:async';
import 'dart:isolate';

import '../../entities/embedding_chunk.dart';
import '../../entities/retrieved_chunk.dart';
import 'cosine_similarity.dart';
import 'vector_index.dart';

/// Keeps a [VectorIndex] in sync with the chunk store between queries.
///
/// Rebuilding on every query would cost more than the brute-force scan it
/// replaces, so the cache tracks a stamp per chunk:
///
/// * nothing changed → search the index;
/// * some chunks changed → search the (stale) index, drop hits that were
///   removed or changed, and score the changed/new chunks exactly. Small
///   indexes are rebuilt inline; large (IVF) ones in a background isolate,
///   swapped in when ready.
class VectorIndexCache {
  VectorIndexCache({this.buildInBackground = true});

  /// Disable in tests to make rebuilds synchronous and deterministic.
  final bool buildInBackground;

  VectorIndex? _index;
  Map<String, String> _stamps = const {};
  Future<void>? _building;

  VectorIndex? get current => _index;

  /// Completes when a background rebuild (if any) has finished.
  Future<void> get idle => _building ?? Future.value();

  Future<List<RetrievedChunk>> search(
    List<double> query,
    List<EmbeddingChunk> chunks, {
    required int limit,
    double minScore = 0.0,
  }) async {
    final live = <String, EmbeddingChunk>{
      for (final c in chunks)
        if (c.embedding.isNotEmpty) c.id: c,
    };
    final stamps = {for (final c in live.values) c.id: _stamp(c)};

    final index = _index;
    if (index == null) {
      if (_isLarge(live.length) && buildInBackground) {
        _scheduleRebuild(live.values.toList(), stamps);
        return _exact(query, live.values, minScore);
      }
      _install(VectorIndex.build(live.values), stamps);
      return _index!.search(query, limit: limit, minScore: minScore);
    }

    final changed = <EmbeddingChunk>[
      for (final entry in live.entries)
        if (_stamps[entry.key] != stamps[entry.key]) entry.value,
    ];
    final removed = _stamps.keys.any((id) => !live.containsKey(id));

    if (changed.isEmpty && !removed) {
      return index.search(query, limit: limit, minScore: minScore);
    }

    if (!_isLarge(live.length) || !buildInBackground) {
      _install(VectorIndex.build(live.values), stamps);
      return _index!.search(query, limit: limit, minScore: minScore);
    }

    _scheduleRebuild(live.values.toList(), stamps);
    final changedIds = {for (final c in changed) c.id};
    final stale = index
        .search(query, limit: limit, minScore: minScore)
        .where(
          (r) =>
              live.containsKey(r.chunk.id) && !changedIds.contains(r.chunk.id),
        );
    final merged = [...stale, ..._exact(query, changed, minScore)];
    _sort(merged);
    return merged;
  }

  void invalidate() {
    _index = null;
    _stamps = const {};
  }

  bool _isLarge(int n) => n >= VectorIndex.ivfThreshold;

  void _install(VectorIndex index, Map<String, String> stamps) {
    _index = index;
    _stamps = stamps;
  }

  void _scheduleRebuild(
    List<EmbeddingChunk> chunks,
    Map<String, String> stamps,
  ) {
    if (_building != null) return;
    _building = Isolate.run(() => VectorIndex.build(chunks))
        .then((index) => _install(index, stamps))
        .catchError((Object _) {})
        .whenComplete(() => _building = null);
  }

  static String _stamp(EmbeddingChunk c) =>
      '${c.updatedAt.microsecondsSinceEpoch}:${c.embedding.length}:'
      '${c.embedding.first}:${c.embedding.last}';

  static List<RetrievedChunk> _exact(
    List<double> query,
    Iterable<EmbeddingChunk> chunks,
    double minScore,
  ) {
    final out = <RetrievedChunk>[];
    for (final c in chunks) {
      if (c.embedding.length != query.length) continue;
      final s = cosineSimilarity(query, c.embedding);
      if (s >= minScore) out.add(RetrievedChunk(chunk: c, similarity: s));
    }
    _sort(out);
    return out;
  }

  static void _sort(List<RetrievedChunk> results) => results.sort((a, b) {
    final bySimilarity = b.similarity.compareTo(a.similarity);
    if (bySimilarity != 0) return bySimilarity;
    return b.chunk.createdAt.compareTo(a.chunk.createdAt);
  });
}
