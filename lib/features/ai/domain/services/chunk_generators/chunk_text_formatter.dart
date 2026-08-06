import 'package:intl/intl.dart';

/// Shared text-formatting helpers used by [ChunkGenerator] implementations.
///
/// Chunks are generated in English because they feed an English-language
/// retrieval and generation pipeline; the locale is intentionally fixed to
/// `en_US` for deterministic, model-facing output.
class ChunkTextFormatter {
  ChunkTextFormatter._();

  /// Formats [amount] as an INR amount without thousand separators and
  /// without trailing zeros for whole numbers (for example `₹500`,
  /// `₹8200`, `₹1234.56`).
  static String currency(double amount) {
    final value = amount == amount.roundToDouble()
        ? amount.toStringAsFixed(0)
        : amount.toStringAsFixed(2);

    return '₹$value';
  }

  /// Formats [date] as a short English date (for example `Aug 2`).
  static String date(DateTime date) {
    return DateFormat('MMM d', 'en_US').format(date);
  }

  /// Formats [date] as a month and year (for example `August 2026`).
  static String monthYear(DateTime date) {
    return DateFormat('MMMM yyyy', 'en_US').format(date);
  }

  /// Returns the singular or plural form of `transaction` for [count].
  static String transactions(int count) {
    return count == 1 ? 'transaction' : 'transactions';
  }
}
