import 'package:equatable/equatable.dart';

import '../../../expense/domain/entities/expense_entity.dart';

/// A spending "Wrapped" for one calendar year, computed on-device.
class YearInReview extends Equatable {
  final int year;
  final double total;
  final int transactions;

  /// Days counted (Jan 1 → today for the current year, else the whole year;
  /// never before the first expense ever logged).
  final int trackedDays;

  /// Top categories by spend, highest first (at most 5).
  final List<MapEntry<String, double>> topCategories;

  /// Most frequent merchant (by visits) and what was spent there.
  final String? topMerchant;
  final int topMerchantVisits;
  final double topMerchantTotal;
  final ExpenseEntity? biggestExpense;

  /// 1–12 → spend.
  final Map<int, double> byMonth;

  /// 1 (Mon) – 7 (Sun) with the most spend.
  final int? busiestWeekday;
  final String? topPaymentMethod;
  final int noSpendDays;
  final int longestNoSpendStreak;

  /// Change vs the previous year over the same span (e.g. Jan–Nov vs
  /// Jan–Nov), as a fraction. `null` when there's nothing to compare.
  final double? changeVsLastYear;

  const YearInReview({
    required this.year,
    required this.total,
    required this.transactions,
    required this.trackedDays,
    required this.topCategories,
    this.topMerchant,
    this.topMerchantVisits = 0,
    this.topMerchantTotal = 0,
    this.biggestExpense,
    required this.byMonth,
    this.busiestWeekday,
    this.topPaymentMethod,
    required this.noSpendDays,
    required this.longestNoSpendStreak,
    this.changeVsLastYear,
  });

  bool get isEmpty => transactions == 0;

  double get perDay => trackedDays <= 0 ? 0 : total / trackedDays;

  int? get busiestMonth {
    if (byMonth.isEmpty) return null;
    return byMonth.entries.reduce((a, b) => b.value > a.value ? b : a).key;
  }

  /// Minimum entries before a Wrapped is worth showing.
  static const minTransactions = 10;

  static YearInReview compute(
    List<ExpenseEntity> expenses,
    int year,
    DateTime now,
  ) {
    final live = expenses.where((e) => !e.isDeleted).toList();
    final start = DateTime(year);
    final today = DateTime(now.year, now.month, now.day);
    final yearEnd = DateTime(year + 1);
    final end = year == now.year ? today.add(const Duration(days: 1)) : yearEnd;

    final inYear = [
      for (final e in live)
        if (!e.date.isBefore(start) && e.date.isBefore(end)) e,
    ];

    var total = 0.0;
    final byCategory = <String, double>{};
    final byMonth = <int, double>{};
    final byWeekday = <int, double>{};
    final merchantVisits = <String, int>{};
    final merchantTotals = <String, double>{};
    final merchantNames = <String, String>{};
    final payments = <String, int>{};
    final spendDays = <DateTime>{};
    ExpenseEntity? biggest;

    for (final e in inYear) {
      total += e.amount;
      byCategory.update(
        e.categoryId,
        (v) => v + e.amount,
        ifAbsent: () => e.amount,
      );
      byMonth.update(
        e.date.month,
        (v) => v + e.amount,
        ifAbsent: () => e.amount,
      );
      byWeekday.update(
        e.date.weekday,
        (v) => v + e.amount,
        ifAbsent: () => e.amount,
      );
      final merchant = e.merchant?.trim();
      if (merchant != null && merchant.isNotEmpty) {
        final key = merchant.toLowerCase();
        merchantVisits.update(key, (v) => v + 1, ifAbsent: () => 1);
        merchantTotals.update(
          key,
          (v) => v + e.amount,
          ifAbsent: () => e.amount,
        );
        merchantNames.putIfAbsent(key, () => merchant);
      }
      final method = e.paymentMethod;
      if (method != null) {
        payments.update(method, (v) => v + 1, ifAbsent: () => 1);
      }
      spendDays.add(DateTime(e.date.year, e.date.month, e.date.day));
      if (biggest == null || e.amount > biggest.amount) biggest = e;
    }

    // Days are only "no-spend" once the user was tracking at all.
    final firstEver = live.isEmpty
        ? null
        : live.map((e) => e.date).reduce((a, b) => a.isBefore(b) ? a : b);
    var trackFrom = start;
    if (firstEver != null) {
      final first = DateTime(firstEver.year, firstEver.month, firstEver.day);
      if (first.isAfter(trackFrom)) trackFrom = first;
    }
    var tracked = 0;
    var noSpend = 0;
    var streak = 0;
    var longest = 0;
    for (
      var d = trackFrom;
      d.isBefore(end);
      d = DateTime(d.year, d.month, d.day + 1)
    ) {
      tracked++;
      if (spendDays.contains(d)) {
        streak = 0;
      } else {
        noSpend++;
        streak++;
        if (streak > longest) longest = streak;
      }
    }

    String? topMerchant;
    if (merchantVisits.isNotEmpty) {
      final best = merchantVisits.entries.reduce((a, b) {
        if (b.value != a.value) return b.value > a.value ? b : a;
        return merchantTotals[b.key]! > merchantTotals[a.key]! ? b : a;
      });
      topMerchant = best.key;
    }

    // Same span last year, for a fair comparison mid-year.
    final prevStart = DateTime(year - 1);
    final prevEnd = DateTime(year - 1, end.month, end.day);
    final prevTotal = live
        .where((e) => !e.date.isBefore(prevStart) && e.date.isBefore(prevEnd))
        .fold<double>(0, (s, e) => s + e.amount);

    final categories = byCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return YearInReview(
      year: year,
      total: total,
      transactions: inYear.length,
      trackedDays: tracked,
      topCategories: categories.take(5).toList(),
      topMerchant: topMerchant == null ? null : merchantNames[topMerchant],
      topMerchantVisits: topMerchant == null ? 0 : merchantVisits[topMerchant]!,
      topMerchantTotal: topMerchant == null ? 0 : merchantTotals[topMerchant]!,
      biggestExpense: biggest,
      byMonth: byMonth,
      busiestWeekday: byWeekday.isEmpty
          ? null
          : byWeekday.entries.reduce((a, b) => b.value > a.value ? b : a).key,
      topPaymentMethod: payments.isEmpty
          ? null
          : payments.entries.reduce((a, b) => b.value > a.value ? b : a).key,
      noSpendDays: noSpend,
      longestNoSpendStreak: longest,
      changeVsLastYear: prevTotal <= 0 ? null : (total - prevTotal) / prevTotal,
    );
  }

  /// Years with at least [minTransactions] expenses, newest first.
  static List<int> availableYears(List<ExpenseEntity> expenses) {
    final counts = <int, int>{};
    for (final e in expenses) {
      if (e.isDeleted) continue;
      counts.update(e.date.year, (v) => v + 1, ifAbsent: () => 1);
    }
    return [
      for (final e in counts.entries)
        if (e.value >= minTransactions) e.key,
    ]..sort((a, b) => b.compareTo(a));
  }

  @override
  List<Object?> get props => [
    year,
    total,
    transactions,
    trackedDays,
    topCategories,
    topMerchant,
    topMerchantVisits,
    topMerchantTotal,
    biggestExpense,
    byMonth,
    busiestWeekday,
    topPaymentMethod,
    noSpendDays,
    longestNoSpendStreak,
    changeVsLastYear,
  ];
}
