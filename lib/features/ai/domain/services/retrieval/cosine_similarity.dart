import 'dart:math' as math;

/// Returns the cosine similarity between two vectors [a] and [b].
///
/// Vectors must have the same length, otherwise an [ArgumentError] is thrown.
/// When either vector is empty or has zero magnitude the result is `0.0`.
double cosineSimilarity(List<double> a, List<double> b) {
  if (a.length != b.length) {
    throw ArgumentError(
      'Vectors must have the same length. Got ${a.length} and ${b.length}.',
    );
  }

  if (a.isEmpty) return 0.0;

  var dotProduct = 0.0;
  var normA = 0.0;
  var normB = 0.0;

  for (var i = 0; i < a.length; i++) {
    dotProduct += a[i] * b[i];
    normA += a[i] * a[i];
    normB += b[i] * b[i];
  }

  final magnitude = math.sqrt(normA) * math.sqrt(normB);
  if (magnitude == 0) return 0.0;

  return dotProduct / magnitude;
}
