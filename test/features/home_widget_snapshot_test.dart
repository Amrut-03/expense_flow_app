import 'package:expense_flow_app/features/home_widget/data/home_widget_sync.dart';
import 'package:expense_flow_app/features/home_widget/domain/home_widget_snapshot.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/expense_factory.dart';

void main() {
  final now = DateTime(2026, 11, 9, 18);
  String fmt(double v) => '₹${v.toStringAsFixed(0)}';

  test('today only, budgets formatted, negatives floored at zero', () {
    final s = HomeWidgetSnapshot.build(
      now: now,
      expenses: [
        expenseOf(amount: 120, date: DateTime(2026, 11, 9, 9)),
        expenseOf(amount: 80, date: DateTime(2026, 11, 9, 13)),
        expenseOf(amount: 500, date: DateTime(2026, 11, 8)),
        expenseOf(amount: 50, date: DateTime(2026, 11, 9), isDeleted: true),
      ],
      hasBudgets: true,
      safeToday: -40,
      overBudgetCount: 0,
      format: fmt,
      appLockEnabled: false,
    );
    expect(s.date, '2026-11-09');
    expect(s.spentToday, '₹200');
    expect(s.safeToSpend, '₹0');
    expect(s.overBudget, isTrue);
    expect(s.hidden, isFalse);
  });

  test('no budgets → no safe-to-spend; app lock hides amounts', () {
    final s = HomeWidgetSnapshot.build(
      now: now,
      expenses: const [],
      hasBudgets: false,
      safeToday: 0,
      overBudgetCount: 0,
      format: fmt,
      appLockEnabled: true,
    );
    expect(s.safeToSpend, isNull);
    expect(s.overBudget, isFalse);
    expect(s.hidden, isTrue);
  });

  test('widget taps map to routes', () {
    expect(
      HomeWidgetSync.routeFor(Uri.parse('expenseflow://add-expense?homeWidget')),
      '/add-expense',
    );
    expect(HomeWidgetSync.routeFor(Uri.parse('expenseflow://open')), '/dashboard');
    expect(HomeWidgetSync.routeFor(Uri.parse('expenseflow://evil')), isNull);
    expect(HomeWidgetSync.routeFor(null), isNull);
  });
}
