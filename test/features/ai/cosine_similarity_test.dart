import 'package:expense_flow_app/features/ai/domain/services/retrieval/cosine_similarity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('cosineSimilarity', () {
    test('is 1 for identical direction regardless of magnitude', () {
      expect(cosineSimilarity([1, 2, 3], [2, 4, 6]), closeTo(1, 1e-12));
    });

    test('is 0 for orthogonal vectors', () {
      expect(cosineSimilarity([1, 0], [0, 1]), closeTo(0, 1e-12));
    });

    test('is -1 for opposite vectors', () {
      expect(cosineSimilarity([1, 1], [-1, -1]), closeTo(-1, 1e-12));
    });

    test('returns 0 for empty vectors', () {
      expect(cosineSimilarity([], []), 0);
    });

    test('returns 0 when either vector has zero magnitude', () {
      expect(cosineSimilarity([0, 0, 0], [1, 2, 3]), 0);
    });

    test('throws on mismatched lengths', () {
      expect(() => cosineSimilarity([1, 2], [1]), throwsArgumentError);
    });
  });
}
