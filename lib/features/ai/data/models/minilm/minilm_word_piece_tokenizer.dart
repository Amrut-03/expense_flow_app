import 'package:expense_flow_app/features/ai/domain/entities/encoded_sequence.dart';
import 'package:expense_flow_app/features/ai/domain/services/embedding/embedding_tokenizer.dart';

import '../../datasources/local/embedding_model_datasource.dart';
import 'minilm_model_config.dart';

/// WordPiece tokenizer for MiniLM sentence-embedding models.
///
/// Loads the vocabulary from [EmbeddingModelDataSource] and encodes raw
/// text into a fixed-length [EncodedSequence] shaped like the
/// all-MiniLM-L6-v2 input tensors: `[CLS] <tokens> [SEP] [PAD]...`.
class MiniLmWordPieceTokenizer implements EmbeddingTokenizer {
  MiniLmWordPieceTokenizer(this._dataSource);

  final EmbeddingModelDataSource _dataSource;

  Map<String, int>? _tokenToId;
  int? _vocabSize;

  static const String _subwordPrefix = '##';

  @override
  int get vocabSize => _vocabSize ?? 0;

  @override
  int get maxTokens => MiniLmModelConfig.maxSequenceLength;

  @override
  Future<void> load() async {
    if (_tokenToId != null) return;

    final raw = await _dataSource.loadVocabulary();
    final tokens = raw
        .split(RegExp(r'\r?\n'))
        .where((line) => line.trim().isNotEmpty)
        .toList();

    _tokenToId = {for (var i = 0; i < tokens.length; i++) tokens[i].trim(): i};
    _vocabSize = tokens.length;
  }

  @override
  Future<EncodedSequence> encode(String text) async {
    final tokenToId = _tokenToId;
    if (tokenToId == null) {
      throw StateError('Tokenizer not loaded. Call load() before encode().');
    }

    final ids = _buildIds(text, tokenToId);

    final maxTokens = this.maxTokens;
    final padCount = (maxTokens - ids.length).clamp(0, maxTokens);
    final inputIds = [...ids, ...List.filled(padCount, 0)];
    final attentionMask =
        List<int>.filled(ids.length, 1) + List<int>.filled(padCount, 0);
    final tokenTypeIds = List<int>.filled(maxTokens, 0);

    return EncodedSequence(
      inputIds: inputIds,
      attentionMask: attentionMask,
      tokenTypeIds: tokenTypeIds,
    );
  }

  List<int> _buildIds(String text, Map<String, int> tokenToId) {
    final clsId = tokenToId[MiniLmModelConfig.clsToken];
    final sepId = tokenToId[MiniLmModelConfig.sepToken];
    final unkId = tokenToId[MiniLmModelConfig.unknownToken] ?? 100;

    if (clsId == null || sepId == null) {
      throw StateError(
        'Vocabulary is missing required special tokens '
        '(${MiniLmModelConfig.clsToken}/${MiniLmModelConfig.sepToken}).',
      );
    }

    final ids = <int>[clsId];

    for (final word in _basicTokenize(text)) {
      for (final subword in _wordPieceSplit(word, tokenToId)) {
        if (ids.length >= maxTokens - 1) break;
        ids.add(tokenToId[subword] ?? unkId);
      }
    }

    ids.add(sepId);

    if (ids.length > maxTokens) {
      return ids.sublist(0, maxTokens);
    }
    return ids;
  }

  /// Normalises [text] and splits it into whitespace/punctuation words.
  List<String> _basicTokenize(String text) {
    final cleaned = _foldAccents(text.toLowerCase());

    return cleaned
        .split(RegExp(r'[^\p{L}\p{N}]+', unicode: true))
        .where((word) => word.isNotEmpty)
        .toList();
  }

  /// Splits a single word into WordPiece subwords using longest-match-first.
  List<String> _wordPieceSplit(String word, Map<String, int> tokenToId) {
    if (tokenToId.containsKey(word)) return [word];

    final subwords = <String>[];
    var start = 0;

    while (start < word.length) {
      var end = word.length;
      var found = '';

      while (start < end) {
        final candidate = start == 0
            ? word.substring(start, end)
            : '$_subwordPrefix${word.substring(start, end)}';

        if (tokenToId.containsKey(candidate)) {
          found = candidate;
          break;
        }
        end -= 1;
      }

      if (found.isEmpty) {
        subwords.add(MiniLmModelConfig.unknownToken);
        start += 1;
      } else {
        subwords.add(found);
        start += found.startsWith(_subwordPrefix)
            ? found.length - _subwordPrefix.length
            : found.length;
      }
    }

    return subwords;
  }

  /// Replaces common accented Latin characters with their unaccented
  /// counterparts so "café" and "cafe" map to the same tokens.
  String _foldAccents(String input) {
    const replacements = <String, String>{
      'à': 'a',
      'á': 'a',
      'â': 'a',
      'ã': 'a',
      'ä': 'a',
      'å': 'a',
      'ā': 'a',
      'ă': 'a',
      'ą': 'a',
      'ç': 'c',
      'ć': 'c',
      'ĉ': 'c',
      'ċ': 'c',
      'č': 'c',
      'è': 'e',
      'é': 'e',
      'ê': 'e',
      'ë': 'e',
      'ē': 'e',
      'ĕ': 'e',
      'ė': 'e',
      'ę': 'e',
      'ě': 'e',
      'ĝ': 'g',
      'ğ': 'g',
      'ġ': 'g',
      'ģ': 'g',
      'ì': 'i',
      'í': 'i',
      'î': 'i',
      'ï': 'i',
      'ī': 'i',
      'ĭ': 'i',
      'į': 'i',
      'ı': 'i',
      'ĵ': 'j',
      'ķ': 'k',
      'ĺ': 'l',
      'ļ': 'l',
      'ľ': 'l',
      'ŀ': 'l',
      'ł': 'l',
      'ñ': 'n',
      'ń': 'n',
      'ņ': 'n',
      'ň': 'n',
      'ŉ': 'n',
      'ò': 'o',
      'ó': 'o',
      'ô': 'o',
      'õ': 'o',
      'ö': 'o',
      'ø': 'o',
      'ō': 'o',
      'ŏ': 'o',
      'ő': 'o',
      'ŕ': 'r',
      'ŗ': 'r',
      'ř': 'r',
      'ś': 's',
      'ŝ': 's',
      'ş': 's',
      'š': 's',
      'ţ': 't',
      'ť': 't',
      'ŧ': 't',
      'ù': 'u',
      'ú': 'u',
      'û': 'u',
      'ü': 'u',
      'ū': 'u',
      'ŭ': 'u',
      'ů': 'u',
      'ű': 'u',
      'ų': 'u',
      'ŵ': 'w',
      'ý': 'y',
      'ÿ': 'y',
      'ŷ': 'y',
      'ź': 'z',
      'ż': 'z',
      'ž': 'z',
      'æ': 'ae',
      'œ': 'oe',
      'ß': 'ss',
      'ð': 'd',
      'þ': 'th',
    };

    final buffer = StringBuffer();
    for (final char in input.split('')) {
      buffer.write(replacements[char] ?? char);
    }
    return buffer.toString();
  }
}
