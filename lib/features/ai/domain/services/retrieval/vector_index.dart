import 'dart:math' as math;
import 'dart:typed_data';

import '../../entities/embedding_chunk.dart';
import '../../entities/retrieved_chunk.dart';
import 'cosine_similarity.dart';

/// In-memory approximate nearest-neighbour index over chunk embeddings.
///
/// * Every vector is stored as **int8 codes + one scale** (symmetric scalar
///   quantisation), 4× smaller than float32 and 8× smaller than the `double`
///   lists Hive hands back. The first pass scores these codes.
/// * Above [ivfThreshold] vectors the index is split into an **IVF**
///   (inverted file): k-means centroids, each owning a posting list. A query
///   only scans the lists of its [probeFraction] nearest centroids instead of
///   every vector.
/// * The best [candidatePool] approximate hits are **re-scored exactly**
///   against the original float embeddings, so quantisation never changes
///   the final similarity values, only which candidates get considered.
///
/// Below [bruteForceThreshold] vectors, search is plain exact brute force:
/// there is nothing to gain and recall stays 100%.
class VectorIndex {
  VectorIndex._(
    this._chunks,
    this._codes,
    this._factors,
    this._dim,
    this._centroids,
    this._lists,
  );

  static const bruteForceThreshold = 512;
  static const ivfThreshold = 2000;

  /// Fraction of IVF lists probed per query (at least [minProbes]).
  static const probeFraction = 0.15;
  static const minProbes = 4;

  /// Exactly re-scored approximate hits per query (at least).
  static const candidatePool = 64;

  final List<EmbeddingChunk> _chunks;

  /// Row-major int8 codes, `_dim` per vector.
  final Int8List _codes;

  /// Per-vector `scale / ‖v‖`: turns an int8 dot product into a cosine.
  final Float32List _factors;
  final int _dim;

  /// Unit-length centroids (row-major) and their posting lists; empty when
  /// the index is flat.
  final Float32List _centroids;
  final List<Int32List> _lists;

  int get length => _chunks.length;
  bool get isPartitioned => _lists.isNotEmpty;
  int get partitionCount => _lists.length;

  /// Bytes used by the quantised vectors (diagnostics / tests).
  int get quantizedBytes => _codes.lengthInBytes + _factors.lengthInBytes;

  static final empty = VectorIndex._(
    const [],
    Int8List(0),
    Float32List(0),
    0,
    Float32List(0),
    const [],
  );

  /// Builds an index from [chunks], skipping chunks without an embedding or
  /// whose dimension differs from the majority.
  factory VectorIndex.build(Iterable<EmbeddingChunk> chunks, {int seed = 7}) {
    final withVectors = chunks.where((c) => c.embedding.isNotEmpty).toList();
    if (withVectors.isEmpty) return empty;

    final dim = _majorityDimension(withVectors);
    final usable = withVectors.where((c) => c.embedding.length == dim).toList();
    final n = usable.length;

    final codes = Int8List(n * dim);
    final factors = Float32List(n);
    for (var i = 0; i < n; i++) {
      factors[i] = quantizeInto(usable[i].embedding, codes, i * dim);
    }

    if (n < ivfThreshold) {
      return VectorIndex._(
        usable,
        codes,
        factors,
        dim,
        Float32List(0),
        const [],
      );
    }

    final (centroids, lists) = _trainIvf(usable, dim, seed);
    return VectorIndex._(usable, codes, factors, dim, centroids, lists);
  }

  /// Quantises [v] into `target[offset, offset + v.length)` and returns the
  /// factor that maps an int8 dot product back to a cosine (`scale / ‖v‖`).
  static double quantizeInto(List<double> v, Int8List target, int offset) {
    var maxAbs = 0.0;
    var normSq = 0.0;
    for (final x in v) {
      final a = x.abs();
      if (a > maxAbs) maxAbs = a;
      normSq += x * x;
    }
    if (maxAbs == 0 || normSq == 0) return 0;
    final scale = maxAbs / 127;
    for (var i = 0; i < v.length; i++) {
      target[offset + i] = (v[i] / scale).round().clamp(-127, 127);
    }
    return scale / math.sqrt(normSq);
  }

  /// Top results for [query], highest similarity first, newest first on ties.
  ///
  /// Returns up to `max(limit, candidatePool)` exactly-scored hits so callers
  /// that deduplicate afterwards still have enough to fill [limit].
  List<RetrievedChunk> search(
    List<double> query, {
    required int limit,
    double minScore = 0.0,
  }) {
    if (_chunks.isEmpty || query.length != _dim) return const [];

    final pool = math.max(limit, candidatePool);
    if (_chunks.length <= bruteForceThreshold) {
      return _exact(query, Iterable<int>.generate(_chunks.length), minScore);
    }

    final q = _unitFloat32(query);
    final candidates = isPartitioned
        ? _approximateIvf(q, pool)
        : _approximateTopN(q, Iterable<int>.generate(_chunks.length), pool);
    return _exact(query, candidates, minScore);
  }

  List<RetrievedChunk> _exact(
    List<double> query,
    Iterable<int> rows,
    double minScore,
  ) {
    final results = <RetrievedChunk>[];
    for (final row in rows) {
      final chunk = _chunks[row];
      final similarity = cosineSimilarity(query, chunk.embedding);
      if (similarity >= minScore) {
        results.add(RetrievedChunk(chunk: chunk, similarity: similarity));
      }
    }
    results.sort((a, b) {
      final bySimilarity = b.similarity.compareTo(a.similarity);
      if (bySimilarity != 0) return bySimilarity;
      return b.chunk.createdAt.compareTo(a.chunk.createdAt);
    });
    return results;
  }

  double _approxScore(Float32List q, int row) {
    final base = row * _dim;
    var dot = 0.0;
    for (var i = 0; i < _dim; i++) {
      dot += q[i] * _codes[base + i];
    }
    return dot * _factors[row];
  }

  /// Rows of the [n] best approximate scores among [rows].
  List<int> _approximateTopN(Float32List q, Iterable<int> rows, int n) {
    final heap = _MinHeap(n);
    for (final row in rows) {
      heap.offer(row, _approxScore(q, row));
    }
    return heap.rows();
  }

  List<int> _approximateIvf(Float32List q, int pool) {
    final k = _lists.length;
    final order = List<int>.generate(k, (i) => i);
    final centroidScores = Float64List(k);
    for (var c = 0; c < k; c++) {
      var dot = 0.0;
      final base = c * _dim;
      for (var i = 0; i < _dim; i++) {
        dot += q[i] * _centroids[base + i];
      }
      centroidScores[c] = dot;
    }
    order.sort((a, b) => centroidScores[b].compareTo(centroidScores[a]));

    final probes = math.max(minProbes, (k * probeFraction).ceil());
    final rows = <int>[];
    var probed = 0;
    // Keep probing past the target if the nearest lists are too small to
    // fill the candidate pool (skewed clusters).
    for (final c in order) {
      if (probed >= probes && rows.length >= pool) break;
      rows.addAll(_lists[c]);
      probed++;
    }
    return _approximateTopN(q, rows, pool);
  }

  Float32List _unitFloat32(List<double> v) {
    var normSq = 0.0;
    for (final x in v) {
      normSq += x * x;
    }
    final inv = normSq == 0 ? 0.0 : 1 / math.sqrt(normSq);
    final out = Float32List(v.length);
    for (var i = 0; i < v.length; i++) {
      out[i] = v[i] * inv;
    }
    return out;
  }

  static int _majorityDimension(List<EmbeddingChunk> chunks) {
    final counts = <int, int>{};
    for (final c in chunks) {
      counts.update(c.embedding.length, (n) => n + 1, ifAbsent: () => 1);
    }
    return counts.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
  }

  /// Spherical k-means on unit vectors (cosine geometry). Deterministic for a
  /// given [seed]; trained on at most [_trainingSample] vectors, then every
  /// vector is assigned to its nearest centroid.
  static (Float32List, List<Int32List>) _trainIvf(
    List<EmbeddingChunk> chunks,
    int dim,
    int seed,
  ) {
    const iterations = 8;
    final n = chunks.length;
    final k = math.sqrt(n).round().clamp(16, 1024);
    final random = math.Random(seed);

    final unit = Float32List(n * dim);
    for (var i = 0; i < n; i++) {
      final v = chunks[i].embedding;
      var normSq = 0.0;
      for (final x in v) {
        normSq += x * x;
      }
      final inv = normSq == 0 ? 0.0 : 1 / math.sqrt(normSq);
      for (var d = 0; d < dim; d++) {
        unit[i * dim + d] = v[d] * inv;
      }
    }

    final sample = n <= _trainingSample
        ? List<int>.generate(n, (i) => i)
        : (List<int>.generate(
            n,
            (i) => i,
          )..shuffle(random)).sublist(0, _trainingSample);

    final centroids = Float32List(k * dim);
    final picks = (List<int>.of(sample)..shuffle(random)).take(k).toList();
    for (var c = 0; c < k; c++) {
      centroids.setRange(c * dim, (c + 1) * dim, unit, picks[c] * dim);
    }

    int nearest(int row) {
      var best = 0;
      var bestScore = double.negativeInfinity;
      final base = row * dim;
      for (var c = 0; c < k; c++) {
        var dot = 0.0;
        final cb = c * dim;
        for (var d = 0; d < dim; d++) {
          dot += unit[base + d] * centroids[cb + d];
        }
        if (dot > bestScore) {
          bestScore = dot;
          best = c;
        }
      }
      return best;
    }

    for (var iter = 0; iter < iterations; iter++) {
      final sums = Float64List(k * dim);
      final counts = Int32List(k);
      for (final row in sample) {
        final c = nearest(row);
        counts[c]++;
        for (var d = 0; d < dim; d++) {
          sums[c * dim + d] += unit[row * dim + d];
        }
      }
      for (var c = 0; c < k; c++) {
        if (counts[c] == 0) {
          // Re-seed an empty cluster from a random sample vector.
          final row = sample[random.nextInt(sample.length)];
          centroids.setRange(c * dim, (c + 1) * dim, unit, row * dim);
          continue;
        }
        var normSq = 0.0;
        for (var d = 0; d < dim; d++) {
          normSq += sums[c * dim + d] * sums[c * dim + d];
        }
        final inv = normSq == 0 ? 0.0 : 1 / math.sqrt(normSq);
        for (var d = 0; d < dim; d++) {
          centroids[c * dim + d] = sums[c * dim + d] * inv;
        }
      }
    }

    final members = List.generate(k, (_) => <int>[]);
    for (var row = 0; row < n; row++) {
      members[nearest(row)].add(row);
    }
    return (centroids, [for (final m in members) Int32List.fromList(m)]);
  }

  static const _trainingSample = 8192;
}

/// Fixed-capacity min-heap keeping the [capacity] highest scores.
class _MinHeap {
  _MinHeap(this.capacity);

  final int capacity;
  final _rows = <int>[];
  final _scores = <double>[];

  void offer(int row, double score) {
    if (_rows.length < capacity) {
      _rows.add(row);
      _scores.add(score);
      _siftUp(_rows.length - 1);
    } else if (score > _scores[0]) {
      _rows[0] = row;
      _scores[0] = score;
      _siftDown(0);
    }
  }

  List<int> rows() => List.of(_rows);

  void _swap(int a, int b) {
    final r = _rows[a];
    _rows[a] = _rows[b];
    _rows[b] = r;
    final s = _scores[a];
    _scores[a] = _scores[b];
    _scores[b] = s;
  }

  void _siftUp(int i) {
    while (i > 0) {
      final parent = (i - 1) >> 1;
      if (_scores[i] >= _scores[parent]) return;
      _swap(i, parent);
      i = parent;
    }
  }

  void _siftDown(int i) {
    final n = _rows.length;
    while (true) {
      final l = 2 * i + 1;
      final r = l + 1;
      var smallest = i;
      if (l < n && _scores[l] < _scores[smallest]) smallest = l;
      if (r < n && _scores[r] < _scores[smallest]) smallest = r;
      if (smallest == i) return;
      _swap(i, smallest);
      i = smallest;
    }
  }
}
