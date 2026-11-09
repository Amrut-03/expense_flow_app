import 'package:equatable/equatable.dart';

import '../../../../core/constants/payment_methods.dart';
import '../../../expense/domain/entities/expense_entity.dart';

class PaymentMethodShare extends Equatable {
  final String method;
  final double amount;
  final int count;

  /// Share of the period total, 0–1.
  final double share;

  const PaymentMethodShare({
    required this.method,
    required this.amount,
    required this.count,
    required this.share,
  });

  @override
  List<Object?> get props => [method, amount, count, share];
}

class PaymentMethodBreakdown extends Equatable {
  /// Methods with spend in the month, largest first.
  final List<PaymentMethodShare> methods;
  final double total;

  /// Share of spend paid digitally (UPI, card, bank transfer), 0–1, for
  /// each of the last few months, oldest first. `null` for months with no
  /// spend.
  final List<double?> digitalShareTrend;

  const PaymentMethodBreakdown({
    required this.methods,
    required this.total,
    required this.digitalShareTrend,
  });

  bool get isEmpty => methods.isEmpty;

  /// Digital share this month, or `null` without spend.
  double? get digitalShare =>
      digitalShareTrend.isEmpty ? null : digitalShareTrend.last;

  /// Change in digital share versus last month in percentage points, when
  /// both months have spend.
  double? get digitalShareChange {
    if (digitalShareTrend.length < 2) return null;
    final now = digitalShareTrend.last;
    final before = digitalShareTrend[digitalShareTrend.length - 2];
    if (now == null || before == null) return null;
    return (now - before) * 100;
  }

  @override
  List<Object?> get props => [methods, total, digitalShareTrend];

  static const digitalMethods = {'UPI', 'Card', 'Bank Transfer'};

  /// Breakdown for the calendar month containing [now], plus a
  /// [trendMonths]-month digital-share trend ending in that month.
  static PaymentMethodBreakdown compute(
    List<ExpenseEntity> expenses, {
    required DateTime now,
    int trendMonths = 6,
  }) {
    final amounts = <String, double>{};
    final counts = <String, int>{};
    final monthStart = DateTime(now.year, now.month);
    final monthEnd = DateTime(now.year, now.month + 1);
    final trendStart = DateTime(now.year, now.month - trendMonths + 1);

    final monthTotals = List<double>.filled(trendMonths, 0);
    final monthDigital = List<double>.filled(trendMonths, 0);

    for (final e in expenses) {
      if (e.isDeleted) continue;
      final method = normalize(e.paymentMethod);

      if (!e.date.isBefore(monthStart) && e.date.isBefore(monthEnd)) {
        amounts.update(method, (v) => v + e.amount, ifAbsent: () => e.amount);
        counts.update(method, (v) => v + 1, ifAbsent: () => 1);
      }

      if (!e.date.isBefore(trendStart) && e.date.isBefore(monthEnd)) {
        final index =
            (e.date.year - trendStart.year) * 12 +
            e.date.month -
            trendStart.month;
        monthTotals[index] += e.amount;
        if (digitalMethods.contains(method)) monthDigital[index] += e.amount;
      }
    }

    final total = amounts.values.fold<double>(0, (a, b) => a + b);
    final methods = [
      for (final entry in amounts.entries)
        PaymentMethodShare(
          method: entry.key,
          amount: entry.value,
          count: counts[entry.key] ?? 0,
          share: total <= 0 ? 0 : entry.value / total,
        ),
    ]..sort((a, b) => b.amount.compareTo(a.amount));

    return PaymentMethodBreakdown(
      methods: methods,
      total: total,
      digitalShareTrend: [
        for (var i = 0; i < trendMonths; i++)
          monthTotals[i] <= 0 ? null : monthDigital[i] / monthTotals[i],
      ],
    );
  }

  /// Maps missing or unknown methods onto [PaymentMethods.all] (`Other`).
  static String normalize(String? method) {
    if (method == null) return 'Other';
    for (final known in PaymentMethods.all) {
      if (known.toLowerCase() == method.trim().toLowerCase()) return known;
    }
    return 'Other';
  }
}
