import 'package:expense_flow_app/features/insights/domain/services/year_in_review.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/expense_factory.dart';

void main() {
  final now = DateTime(2026, 3, 10);

  test('summarises a year in progress', () {
    final expenses = [
      expenseOf(amount: 100, date: DateTime(2026, 1, 1), merchant: 'Swiggy',
          paymentMethod: 'upi'),
      expenseOf(amount: 200, date: DateTime(2026, 1, 2), merchant: 'swiggy ',
          paymentMethod: 'upi'),
      expenseOf(amount: 5000, date: DateTime(2026, 2, 14),
          categoryId: 'shopping', merchant: 'Myntra', paymentMethod: 'card'),
      expenseOf(amount: 300, date: DateTime(2026, 3, 9), merchant: 'Swiggy'),
      expenseOf(amount: 999, date: DateTime(2026, 3, 9), isDeleted: true),
      expenseOf(amount: 2800, date: DateTime(2025, 2, 1)),
      expenseOf(amount: 9000, date: DateTime(2025, 6, 1)),
    ];
    final r = YearInReview.compute(expenses, 2026, now);
    expect(r.total, 5600);
    expect(r.transactions, 4);
    expect(r.topCategories.first.key, 'shopping');
    expect(r.topMerchant, 'Swiggy');
    expect(r.topMerchantVisits, 3);
    expect(r.topMerchantTotal, 600);
    expect(r.biggestExpense!.amount, 5000);
    expect(r.busiestMonth, 2);
    expect(r.topPaymentMethod, 'upi');
    // Jan 1 → Mar 10 inclusive = 69 days, 4 spend days.
    expect(r.trackedDays, 69);
    expect(r.noSpendDays, 65);
    // Jan 3 → Feb 13 = 42 days in a row.
    expect(r.longestNoSpendStreak, 42);
    expect(r.changeVsLastYear, closeTo((5600 - 2800) / 2800, 1e-9));
  });

  test('no-spend days only count from the first expense ever', () {
    final r = YearInReview.compute(
      [expenseOf(amount: 10, date: DateTime(2026, 3, 1))],
      2026,
      now,
    );
    expect(r.trackedDays, 10);
    expect(r.noSpendDays, 9);
    expect(r.changeVsLastYear, isNull);
  });

  test('years need enough expenses to be offered', () {
    final expenses = [
      for (var i = 0; i < YearInReview.minTransactions; i++)
        expenseOf(amount: 1, date: DateTime(2025, 1, i + 1)),
      expenseOf(amount: 1, date: DateTime(2026, 1, 1)),
    ];
    expect(YearInReview.availableYears(expenses), [2025]);
  });
}
