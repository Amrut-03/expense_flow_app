import 'package:equatable/equatable.dart';

import '../entities/group.dart';

/// Suggested payment to settle up.
class Transfer extends Equatable {
  final String from;
  final String to;
  final double amount;

  const Transfer(this.from, this.to, this.amount);

  @override
  List<Object?> get props => [from, to, amount];

  @override
  String toString() => 'Transfer($from → $to: $amount)';
}

/// Split and balance maths in integer paise, so shares always add up exactly.
abstract final class SplitMath {
  static int toPaise(double inr) => (inr * 100).round();
  static double fromPaise(int paise) => paise / 100;

  /// Equal split; leftover paise go to the first members (stable order),
  /// e.g. ₹100 / 3 → 33.34, 33.33, 33.33.
  static Map<String, double> equal(double amount, List<String> uids) {
    if (uids.isEmpty) throw ArgumentError('No one to split with');
    final total = toPaise(amount);
    final base = total ~/ uids.length;
    var rest = total - base * uids.length;
    return {
      for (final uid in uids) uid: fromPaise(base + (rest-- > 0 ? 1 : 0)),
    };
  }

  /// Whether custom shares add up to [amount] (to the paisa).
  static bool sharesMatch(double amount, Map<String, double> shares) =>
      shares.values.every((v) => v >= 0) &&
      shares.values.fold<int>(0, (s, v) => s + toPaise(v)) == toPaise(amount);

  /// Net position per member in INR: positive = is owed, negative = owes.
  static Map<String, double> balances({
    required List<String> members,
    required List<GroupExpense> expenses,
    required List<GroupSettlement> settlements,
  }) {
    final paise = {for (final m in members) m: 0};
    void add(String uid, int v) => paise[uid] = (paise[uid] ?? 0) + v;
    for (final e in expenses) {
      add(e.paidBy, toPaise(e.amount));
      for (final s in e.shares.entries) {
        add(s.key, -toPaise(s.value));
      }
    }
    for (final s in settlements) {
      add(s.from, toPaise(s.amount));
      add(s.to, -toPaise(s.amount));
    }
    return {for (final e in paise.entries) e.key: fromPaise(e.value)};
  }

  /// Fewest-ish payments that settle everyone: repeatedly match the biggest
  /// debtor with the biggest creditor (at most n−1 transfers).
  static List<Transfer> settleUp(Map<String, double> balances) {
    final debtors = [
      for (final e in balances.entries)
        if (toPaise(e.value) < 0) [e.key, -toPaise(e.value)],
    ];
    final creditors = [
      for (final e in balances.entries)
        if (toPaise(e.value) > 0) [e.key, toPaise(e.value)],
    ];
    int byAmount(List<Object> a, List<Object> b) =>
        (b[1] as int).compareTo(a[1] as int);
    final transfers = <Transfer>[];
    while (debtors.isNotEmpty && creditors.isNotEmpty) {
      debtors.sort(byAmount);
      creditors.sort(byAmount);
      final d = debtors.first;
      final c = creditors.first;
      final pay = (d[1] as int) < (c[1] as int) ? d[1] as int : c[1] as int;
      transfers.add(Transfer(d[0] as String, c[0] as String, fromPaise(pay)));
      d[1] = (d[1] as int) - pay;
      c[1] = (c[1] as int) - pay;
      if (d[1] == 0) debtors.removeAt(0);
      if (c[1] == 0) creditors.removeAt(0);
    }
    return transfers;
  }

  /// Group spend in the calendar month of [now] (sum of expenses).
  static double spentThisMonth(List<GroupExpense> expenses, DateTime now) =>
      expenses
          .where((e) => e.date.year == now.year && e.date.month == now.month)
          .fold(0, (s, e) => s + e.amount);
}
