import '../../../categories/domain/services/category_suggester.dart';
import '../../../expense/domain/entities/expense_entity.dart';
import '../entities/receipt_draft.dart';
import '../services/receipt_parser.dart';
import '../services/receipt_recognizer.dart';

/// Photo → OCR → parsed draft with a suggested category. Never saves.
class ScanReceiptUseCase {
  ScanReceiptUseCase(this.recognizer, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final ReceiptRecognizer recognizer;
  final DateTime Function() _now;

  Future<ReceiptDraft> call(
    String imagePath, {
    required List<ExpenseEntity> history,
    required bool Function(String categoryId) isAvailable,
  }) async {
    final lines = await recognizer.recognize(imagePath);
    final draft = ReceiptParser.parse(lines, now: _now());
    final suggestion = CategorySuggester.suggest(
      merchant: draft.merchant,
      title: draft.items.isEmpty ? null : draft.items.first.name,
      history: history,
      isAvailable: isAvailable,
    );
    return draft.copyWith(categoryId: suggestion?.categoryId);
  }
}
