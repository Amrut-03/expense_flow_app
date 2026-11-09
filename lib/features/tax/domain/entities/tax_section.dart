/// Indian income-tax deductions an expense can count towards.
///
/// These deductions apply under the **old** tax regime only. Caps are the
/// statutory limits for FY 2025-26 and are shown as guidance, not advice.
enum TaxSection {
  /// Life insurance, PPF, ELSS, tuition fees, home-loan principal…
  s80C('80C', '🏛️', 150000),

  /// Health insurance premiums and preventive check-ups (self/family,
  /// below 60). Senior citizens can claim up to ₹50,000.
  s80D('80D', '🩺', 25000),

  /// House rent paid. The exempt amount depends on salary and city, so
  /// there is no fixed cap.
  hra('HRA', '🏠', null),

  /// Donations to eligible charities (50% or 100% deductible).
  s80G('80G', '🤝', null),

  /// Interest on an education loan, no upper limit.
  s80E('80E', '🎓', null);

  const TaxSection(this.code, this.emoji, this.cap);

  /// Stored on the expense (`ExpenseEntity.taxTag`).
  final String code;
  final String emoji;

  /// Maximum deductible amount in INR, or `null` when uncapped/variable.
  final double? cap;

  static TaxSection? fromCode(String? code) {
    if (code == null) return null;
    for (final s in values) {
      if (s.code == code) return s;
    }
    return null;
  }
}

/// The Indian financial year (1 April – 31 March) containing [date].
class FinancialYear {
  /// Calendar year in which the FY starts (FY 2026-27 → 2026).
  final int startYear;

  const FinancialYear(this.startYear);

  factory FinancialYear.of(DateTime date) =>
      FinancialYear(date.month >= DateTime.april ? date.year : date.year - 1);

  DateTime get start => DateTime(startYear, DateTime.april);

  /// Exclusive end.
  DateTime get end => DateTime(startYear + 1, DateTime.april);

  bool contains(DateTime date) => !date.isBefore(start) && date.isBefore(end);

  FinancialYear get previous => FinancialYear(startYear - 1);

  /// `FY 2026-27`.
  String get label =>
      'FY $startYear-${((startYear + 1) % 100).toString().padLeft(2, '0')}';

  @override
  bool operator ==(Object other) =>
      other is FinancialYear && other.startYear == startYear;

  @override
  int get hashCode => startYear.hashCode;
}
