import 'package:equatable/equatable.dart';

/// The numerical representation of a piece of text ready for model
/// inference.
///
/// Produced by an [EmbeddingTokenizer] and consumed by an [EmbeddingModel].
/// Each list is padded to the model's maximum sequence length so the input
/// tensors always have a fixed shape.
class EncodedSequence extends Equatable {
  /// Token ids for every position in the sequence (including special
  /// `[CLS]`/`[SEP]` tokens), padded with the pad id.
  final List<int> inputIds;

  /// `1` for real tokens and `0` for padding.
  final List<int> attentionMask;

  /// Segment ids; single-segment MiniLM models use all zeroes.
  final List<int> tokenTypeIds;

  const EncodedSequence({
    required this.inputIds,
    required this.attentionMask,
    this.tokenTypeIds = const [],
  });

  @override
  List<Object?> get props => [inputIds, attentionMask, tokenTypeIds];
}
