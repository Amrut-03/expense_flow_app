import 'dart:math' as math;
import 'dart:typed_data';

import 'package:expense_flow_app/features/ai/domain/entities/embedding_chunk.dart';
import 'package:expense_flow_app/features/ai/domain/services/retrieval/cosine_similarity.dart';
import 'package:expense_flow_app/features/ai/domain/services/retrieval/vector_index.dart';
import 'package:expense_flow_app/features/ai/domain/services/retrieval/vector_index_cache.dart';
import 'package:flutter_test/flutter_test.dart';

const _dim = 64;

/// Clustered unit-ish vectors, like real sentence embeddings (topics).
List<EmbeddingChunk> _corpus(int n, {int topics = 40, int seed = 1}) {
  final r = math.Random(seed);
  final centres = List.generate(
    topics,
    (_) => List.generate(_dim, (_) => r.nextDouble() * 2 - 1),
  );
  final t0 = DateTime(2026);
  return List.generate(n, (i) {
    final c = centres[r.nextInt(topics)];
    return EmbeddingChunk(
      id: 'c$i',
      chunkType: 'transaction',
      text: 't$i',
      sourceId: 's$i',
      embedding: [for (final x in c) x + (r.nextDouble() - .5) * .6],
      createdAt: t0.add(Duration(minutes: i)),
      updatedAt: t0,
      needsEmbedding: false,
    );
  });
}

List<String> _bruteTop(List<double> q, List<EmbeddingChunk> all, int k) {
  final scored = [for (final c in all) (c.id, cosineSimilarity(q, c.embedding))]
    ..sort((a, b) => b.$2.compareTo(a.$2));
  return [for (final s in scored.take(k)) s.$1];
}

void main() {
  test('int8 quantisation keeps cosine within 1%', () {
    final r = math.Random(3);
    final a = List.generate(384, (_) => r.nextDouble() * 2 - 1);
    final b = List.generate(384, (_) => r.nextDouble() * 2 - 1);
    final codesA = Int8List(384);
    final codesB = Int8List(384);
    final fa = VectorIndex.quantizeInto(a, codesA, 0);
    final fb = VectorIndex.quantizeInto(b, codesB, 0);
    var dot = 0;
    for (var i = 0; i < 384; i++) {
      dot += codesA[i] * codesB[i];
    }
    expect(dot * fa * fb, closeTo(cosineSimilarity(a, b), 0.01));
  });

  test('small stores use exact brute force', () {
    final corpus = _corpus(200);
    final index = VectorIndex.build(corpus);
    expect(index.isPartitioned, isFalse);
    final q = corpus[17].embedding;
    final hits = index.search(q, limit: 5);
    expect(hits.first.chunk.id, 'c17');
    expect(
      [for (final h in hits.take(5)) h.chunk.id],
      _bruteTop(q, corpus, 5),
    );
  });

  test('large stores are IVF-partitioned with high recall@5', () {
    final corpus = _corpus(6000);
    final index = VectorIndex.build(corpus);
    expect(index.isPartitioned, isTrue);
    expect(index.partitionCount, greaterThanOrEqualTo(16));
    // int8 codes + one float per vector, vs 8 bytes per double.
    expect(index.quantizedBytes, lessThan(6000 * _dim * 8 ~/ 6));

    final r = math.Random(9);
    var found = 0;
    const queries = 40;
    for (var i = 0; i < queries; i++) {
      final q = corpus[r.nextInt(corpus.length)].embedding;
      final truth = _bruteTop(q, corpus, 5).toSet();
      final got = index.search(q, limit: 5).take(5).map((h) => h.chunk.id);
      found += got.where(truth.contains).length;
    }
    expect(found / (queries * 5), greaterThanOrEqualTo(0.95));
  });

  test('similarities are exact (re-scored), not quantised', () {
    final corpus = _corpus(3000);
    final q = corpus[5].embedding;
    final hit = VectorIndex.build(corpus).search(q, limit: 1).first;
    expect(hit.similarity, cosineSimilarity(q, hit.chunk.embedding));
  });

  test('skips chunks without or with mismatched embeddings', () {
    final corpus = _corpus(10);
    final odd = corpus.first.copyWith(id: 'odd', embedding: [1, 2, 3]);
    final empty = corpus.first.copyWith(id: 'none', embedding: const []);
    final index = VectorIndex.build([...corpus, odd, empty]);
    expect(index.length, 10);
    expect(index.search([1, 2, 3], limit: 3), isEmpty);
  });

  group('VectorIndexCache', () {
    test('reuses the index until a chunk changes', () async {
      final cache = VectorIndexCache(buildInBackground: false);
      final corpus = _corpus(100);
      await cache.search(corpus[0].embedding, corpus, limit: 3);
      final first = cache.current;
      await cache.search(corpus[1].embedding, corpus, limit: 3);
      expect(identical(cache.current, first), isTrue);

      final changed = [
        ...corpus.skip(1),
        corpus[0].copyWith(
          embedding: corpus[50].embedding,
          updatedAt: DateTime(2027),
        ),
      ];
      final hits = await cache.search(corpus[50].embedding, changed, limit: 3);
      expect(identical(cache.current, first), isFalse);
      expect(hits.take(2).map((h) => h.chunk.id), containsAll(['c0', 'c50']));
    });

    test('large store: serves stale index + exact delta while rebuilding',
        () async {
      final cache = VectorIndexCache();
      final corpus = _corpus(2500);
      // First query: no index yet → exact answer, background build starts.
      final cold = await cache.search(corpus[3].embedding, corpus, limit: 3);
      expect(cold.first.chunk.id, 'c3');
      await cache.idle;
      expect(cache.current!.isPartitioned, isTrue);
      final built = cache.current;

      final fresh = corpus[3].copyWith(id: 'new', updatedAt: DateTime(2027));
      final removedOne = [...corpus.skip(1), fresh];
      final hits =
          await cache.search(corpus[3].embedding, removedOne, limit: 3);
      expect(hits.map((h) => h.chunk.id), contains('new'));
      expect(hits.map((h) => h.chunk.id), isNot(contains('c0')));
      await cache.idle;
      expect(identical(cache.current, built), isFalse);
      expect(cache.current!.length, 2500);
    });
  });
}
