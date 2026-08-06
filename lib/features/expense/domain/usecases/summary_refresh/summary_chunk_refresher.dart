/// A chunk the refresh pipeline would like to have persisted, before any
/// diff against what is already stored.
class DesiredChunk {
  /// Stable identifier of the chunk.
  final String id;

  /// Discriminates the kind of content stored in [text].
  final String chunkType;

  /// Normalised, plain-text content of the chunk.
  final String text;

  /// Identifier of the source entity this chunk was derived from.
  final String sourceId;

  const DesiredChunk({
    required this.id,
    required this.chunkType,
    required this.text,
    required this.sourceId,
  });
}

/// Computes the desired state for one family of summary chunks.
///
/// Implementations are deliberately stateless and may be re-run on every
/// refresh; the coordinator decides whether anything actually changed. This
/// is the extension point for adding new summary types (for example savings
/// goals or subscriptions) without touching the coordinator.
abstract interface class SummaryChunkRefresher {
  /// Returns the full set of chunks this refresher wants persisted right now.
  Future<List<DesiredChunk>> refresh();
}
