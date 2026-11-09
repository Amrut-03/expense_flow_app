import 'package:equatable/equatable.dart';

/// Money moved between two envelopes within one month (INR).
class EnvelopeMove extends Equatable {
  final DateTime month;
  final String fromCategoryId;
  final String toCategoryId;
  final double amount;

  const EnvelopeMove({
    required this.month,
    required this.fromCategoryId,
    required this.toCategoryId,
    required this.amount,
  });

  Map<String, dynamic> toMap() => {
    'month': month.toIso8601String(),
    'from': fromCategoryId,
    'to': toCategoryId,
    'amount': amount,
  };

  static EnvelopeMove? fromMap(Object? raw) {
    if (raw is! Map) return null;
    final month = DateTime.tryParse(raw['month'] as String? ?? '');
    final from = raw['from'];
    final to = raw['to'];
    final amount = (raw['amount'] as num?)?.toDouble();
    if (month == null || from is! String || to is! String || amount == null) {
      return null;
    }
    return EnvelopeMove(
      month: month,
      fromCategoryId: from,
      toCategoryId: to,
      amount: amount,
    );
  }

  @override
  List<Object?> get props => [month, fromCategoryId, toCategoryId, amount];
}

/// Envelope-mode configuration.
class EnvelopeSettings extends Equatable {
  final bool enabled;

  /// First month envelopes ran; balances carry from here.
  final DateTime? startMonth;

  /// Money to assign per month (`yyyy-MM` → INR). A month without an entry
  /// uses the latest earlier one.
  final Map<String, double> incomeByMonth;
  final List<EnvelopeMove> moves;

  const EnvelopeSettings({
    this.enabled = false,
    this.startMonth,
    this.incomeByMonth = const {},
    this.moves = const [],
  });

  static String monthKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}';

  double? incomeFor(DateTime month) {
    final key = monthKey(month);
    String? best;
    for (final k in incomeByMonth.keys) {
      if (k.compareTo(key) <= 0 && (best == null || k.compareTo(best) > 0)) {
        best = k;
      }
    }
    return best == null ? null : incomeByMonth[best];
  }

  @override
  List<Object?> get props => [enabled, startMonth, incomeByMonth, moves];
}

/// One envelope's state for a month.
class EnvelopeBalance extends Equatable {
  final String categoryId;

  /// Monthly allocation (the category's budget limit).
  final double assigned;

  /// Balance carried from last month (negative when overspent).
  final double carried;

  /// Net money moved in (+) or out (−) this month.
  final double moved;
  final double spent;

  const EnvelopeBalance({
    required this.categoryId,
    required this.assigned,
    required this.carried,
    required this.moved,
    required this.spent,
  });

  /// What's left to spend this month.
  double get available => assigned + carried + moved - spent;

  /// Amount added to the plain limit for budget maths (carry + moves).
  double get adjustment => carried + moved;

  @override
  List<Object?> get props => [categoryId, assigned, carried, moved, spent];
}

class EnvelopeMonth extends Equatable {
  final DateTime month;
  final double? income;
  final List<EnvelopeBalance> envelopes;

  const EnvelopeMonth({
    required this.month,
    required this.income,
    required this.envelopes,
  });

  double get totalAssigned => envelopes.fold(0, (s, e) => s + e.assigned);

  /// Zero-based: income minus everything assigned. Positive means money
  /// still needs a job; negative means more was assigned than earned.
  double? get toBeAssigned => income == null ? null : income! - totalAssigned;

  List<EnvelopeBalance> get overspent =>
      envelopes.where((e) => e.available < -0.005).toList();

  EnvelopeBalance? byCategory(String id) =>
      envelopes.where((e) => e.categoryId == id).firstOrNull;

  @override
  List<Object?> get props => [month, income, envelopes];
}
