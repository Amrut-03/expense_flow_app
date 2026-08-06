import 'package:intl/intl.dart';

/// Formats an INR amount for notification bodies (e.g. `₹1,050`).
///
/// Amounts are stored internally in INR across the app; these messages are
/// intentionally currency-locale-free so they read consistently regardless of
/// the user's display currency preference.
String formatInr(double amount) {
  return NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  ).format(amount);
}
