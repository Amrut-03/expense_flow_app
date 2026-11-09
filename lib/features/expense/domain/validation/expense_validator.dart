import '../../../../core/constants/note_limits.dart';

/// Business rules shared by every use case that writes an expense.
///
/// Throws an [Exception] with a user-facing message on the first violation,
/// matching how the add/update use cases have always reported errors.
abstract final class ExpenseValidator {
  static const double maxAmount = 1000000;

  static void validate({
    required double amount,
    required String categoryId,
    String? note,
    String? title,
    String? merchant,
    double? originalAmount,
    double? exchangeRate,
  }) {
    if (amount <= 0) {
      throw Exception('Amount must be greater than 0');
    }

    final cents = (amount * 100).round();

    if ((amount - cents / 100).abs() > 1e-6) {
      throw Exception('Amount can have maximum 2 decimal places');
    }

    if (amount > maxAmount) {
      throw Exception('Amount exceeds allowed limit');
    }

    if (originalAmount != null && originalAmount <= 0) {
      throw Exception('Original amount must be greater than 0');
    }

    if (exchangeRate != null && exchangeRate <= 0) {
      throw Exception('Exchange rate must be greater than 0');
    }

    if (categoryId.trim().isEmpty) {
      throw Exception('Category is required');
    }

    if ((note?.length ?? 0) > NoteLimits.maxLength) {
      throw Exception('Note cannot exceed ${NoteLimits.maxLength} characters');
    }

    if ((title?.length ?? 0) > NoteLimits.titleMaxLength) {
      throw Exception(
        'Title cannot exceed ${NoteLimits.titleMaxLength} characters',
      );
    }

    if ((merchant?.length ?? 0) > NoteLimits.merchantMaxLength) {
      throw Exception(
        'Merchant cannot exceed ${NoteLimits.merchantMaxLength} characters',
      );
    }
  }

  /// Trims [value] and collapses blank input to `null`.
  static String? clean(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }
}
