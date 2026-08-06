/// Contract implemented by every chunk generator.
///
/// Each generator turns a specific neutral input type into a single
/// natural-language chunk (a [String]) tagged with a stable [chunkType]
/// discriminator. Generators are pure domain services: they never touch
/// Hive, networking, or Flutter, so they are trivially testable and can
/// run fully offline.
abstract interface class ChunkGenerator<T extends Object> {
  /// Stable discriminator of the generated chunk kind.
  ///
  /// Aligned with the `chunkType` field of the AI storage layer, for
  /// example `'transaction'`, `'monthly_summary'`, or `'budget'`.
  String get chunkType;

  /// Produces the natural-language representation of [input].
  String generate(T input);
}
