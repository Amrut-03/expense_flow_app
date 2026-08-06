import 'dart:math' as math;

import '../../entities/embedding_chunk.dart';
import '../../entities/retrieved_chunk.dart';
import '../../repositories/embedding_chunk_repository.dart';
import 'retrieval_service.dart';

/// Topic-based, lexical retrieval used as the current production scaffold.
///
/// Ranks persisted chunks without vectors by scoring how well the query's
/// terms match each chunk's natural-language text. Because chunk text embeds
/// merchant names, category names, budget names, and savings-goal names (see
/// the chunk generators), keyword matching over that text surfaces all of
/// those entity types.
///
/// Scoring combines:
///  1. a coverage term: the fraction of query term weight (inverse document
///     frequency across the corpus) that appears in the chunk, giving bonus
///     to rarer, more specific terms, and
///  2. a recency boost: recently updated chunks rank slightly ahead of
///     older ones at equal relevance.
///
/// TODO(embedding): remove this class once [VectorRetrievalService] is
/// restored as the primary retriever; keyword matching trades away semantic
/// recall in exchange for not requiring a working embedding model.
class LexicalRetrievalService implements RetrievalService {
  LexicalRetrievalService({required this.chunkRepository});

  final EmbeddingChunkRepository chunkRepository;

  /// Splits text into lowercase, alphanumeric tokens.
  static final RegExp _tokenSplit = RegExp(r'[^\p{L}\p{N}]+', unicode: true);

  /// Amount (`0.0` to `1.0`) by which recent chunks are rewarded on top of
  /// their base relevance score.
  static const double recencyBoostStrength = 0.15;

  /// Shortest query term that still contributes to scoring.
  static const int minTokenLength = 1;

  /// Function words dropped from the query so they do not dilute term weight.
  static const Set<String> _stopWords = {
    'a',
    'an',
    'the',
    'how',
    'what',
    'when',
    'where',
    'which',
    'who',
    'much',
    'many',
    'is',
    'are',
    'was',
    'were',
    'and',
    'or',
    'but',
    'of',
    'to',
    'in',
    'on',
    'for',
    'my',
    'your',
    'this',
    'that',
    'me',
    'you',
    'it',
    'i',
    'we',
    'they',
    'do',
    'did',
    'does',
    'spent',
    'spend',
    'total',
    'totals',
    'show',
    'give',
    'tell',
  };

  @override
  Future<List<RetrievedChunk>> retrieve({
    required String query,
    int topK = RetrievalService.defaultTopK,
    double minScore = 0.0,
  }) async {
    if (topK < 1) {
      throw ArgumentError.value(
        topK,
        'topK',
        'Must be greater than or equal to 1.',
      );
    }
    if (minScore < -1.0 || minScore > 1.0) {
      throw ArgumentError.value(
        minScore,
        'minScore',
        'Must be within the range [-1, 1].',
      );
    }

    final chunks = await chunkRepository.getAllChunks();
    if (chunks.isEmpty) return const [];

    // Fallback when the query carries no meaningful tokens (or stop words
    // only): return the most recently updated chunks so the model still has
    // context to work with.
    final queryTokens = _tokens(query);
    if (queryTokens.isEmpty) {
      return _mostRecent(chunks, topK);
    }

    final idf = _computeIdf(chunks, queryTokens);

    var anyTermMatch = false;
    final scored = <RetrievedChunk>[];
    for (final chunk in chunks) {
      final similarity = _scoreChunk(chunk, queryTokens, idf);
      // A zero score means the chunk shares no term with the query; exclude
      // it even when minScore defaults to 0.0 so irrelevant context is never
      // injected into the prompt.
      if (similarity > 0) anyTermMatch = true;
      if (similarity <= 0 || similarity < minScore) continue;
      scored.add(RetrievedChunk(chunk: chunk, similarity: similarity));
    }

    // If no chunk shared any term with the query (common for natural-language
    // questions like "tell me about my recent transaction" that share no words
    // with the chunk text), fall back to the most recent data so the model
    // still has the user's real information to answer from. A stricter
    // minScore filtering everything out is not treated as a miss.
    if (!anyTermMatch) {
      return _mostRecent(chunks, topK);
    }

    scored.sort((a, b) {
      final bySimilarity = b.similarity.compareTo(a.similarity);
      if (bySimilarity != 0) return bySimilarity;
      return b.chunk.updatedAt.compareTo(a.chunk.updatedAt);
    });

    final deduped = _removeDuplicates(scored);

    if (deduped.length <= topK) return deduped;
    return deduped.sublist(0, topK);
  }

  /// Returns the [topK] most recently updated chunks.
  List<RetrievedChunk> _mostRecent(List<EmbeddingChunk> chunks, int topK) {
    final recent = List<EmbeddingChunk>.of(chunks)
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return recent
        .take(topK)
        .map((c) => RetrievedChunk(chunk: c, similarity: 1.0))
        .toList();
  }

  /// Returns `log(totalChunks / docFreq)` for each query term so rarer,
  /// more specific terms dominate the coverage score.
  Map<String, double> _computeIdf(
    List<EmbeddingChunk> chunks,
    List<String> queryTokens,
  ) {
    final querySet = queryTokens.toSet();
    final total = chunks.length;

    return {
      for (final token in querySet)
        token: _idfValue(total, _docCount(chunks, token)),
    };
  }

  int _docCount(List<EmbeddingChunk> chunks, String token) {
    var count = 0;
    for (final chunk in chunks) {
      if (_chunkContainsTerm(chunk, token)) count++;
    }
    return count;
  }

  double _idfValue(int totalChunks, int docCount) {
    // Smoothed idf (`1 + log(N/df)`): matched terms always carry positive
    // weight, while rarer, more specific terms still dominate.
    if (docCount == 0) return 1.0 + math.log(totalChunks.toDouble() + 1.0);
    return 1.0 + math.log(totalChunks.toDouble() / docCount.toDouble());
  }

  /// Base coverage (matched query-term weight over total query weight) plus
  /// a recency boost, normalised to `0.0` to `1.0`.
  double _scoreChunk(
    EmbeddingChunk chunk,
    List<String> queryTokens,
    Map<String, double> idf,
  ) {
    final chunkTokens = _tokens(chunk.text);

    var matchedWeight = 0.0;
    var totalWeight = 0.0;

    for (final token in queryTokens) {
      final weight = idf[token] ?? 0.0;
      totalWeight += weight;
      if (_containsToken(chunkTokens, token) ||
          _chunkContainsTerm(chunk, token)) {
        matchedWeight += weight;
      }
    }

    if (totalWeight == 0) return 0.0;

    final coverage = matchedWeight / totalWeight;
    final recency = _recency(chunk);

    return math.min(1.0, coverage + recencyBoostStrength * coverage * recency);
  }

  double _recency(EmbeddingChunk chunk) {
    final ageDays = DateTime.now().difference(chunk.updatedAt).inHours / 24.0;
    if (ageDays <= 0) return 1.0;

    // Decays from 1.0 (now) towards ~0.1 over ~30 days.
    return 1.0 / (1.0 + ageDays / 10.0);
  }

  List<String> _tokens(String text) {
    return text
        .toLowerCase()
        .split(_tokenSplit)
        .where((t) => t.isNotEmpty && t.length >= minTokenLength)
        .where((t) => !_stopWords.contains(t))
        .toList();
  }

  bool _containsToken(List<String> tokens, String token) {
    return tokens.contains(token);
  }

  /// Token- or prefix-level match against the chunk's raw text and chunk type,
  /// so `domino` matches `Dominos`, `grocer` matches `Grocery`, and a query
  /// term like `transaction`, `budget` or `category` matches the corresponding
  /// [EmbeddingChunk.chunkType] even though those words never appear in the
  /// natural-language chunk text itself.
  bool _chunkContainsTerm(EmbeddingChunk chunk, String token) {
    return _wordMatches(chunk.text, token) ||
        _wordMatches(chunk.chunkType, token);
  }

  bool _wordMatches(String text, String token) {
    final lowerText = text.toLowerCase();
    return lowerText.split(_tokenSplit).any((word) {
      if (word.isEmpty) return false;
      return word == token || word.startsWith(token) || token.startsWith(word);
    });
  }

  /// Keeps the highest-ranked instance of each chunk, where a chunk is
  /// identified by its source entity and type (already relevance-sorted).
  List<RetrievedChunk> _removeDuplicates(List<RetrievedChunk> scored) {
    final seenKeys = <String>{};
    final deduped = <RetrievedChunk>[];

    for (final result in scored) {
      final key = '${result.chunk.chunkType}|${result.chunk.sourceId}';
      if (seenKeys.add(key)) {
        deduped.add(result);
      }
    }

    return deduped;
  }
}
