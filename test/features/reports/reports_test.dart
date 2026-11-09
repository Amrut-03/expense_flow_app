import 'package:expense_flow_app/features/reports/data/pdf_statement_renderer.dart';
import 'package:expense_flow_app/features/reports/domain/services/expense_csv_builder.dart';
import 'package:expense_flow_app/features/reports/domain/services/monthly_statement.dart';
import 'package:expense_flow_app/features/reports/domain/usecases/export_usecases.dart';
import 'package:expense_flow_app/features/tax/domain/entities/tax_section.dart';
import 'package:expense_flow_app/features/tax/domain/usecases/get_tax_summary_usecase.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/expense_factory.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ExpenseCsvBuilder', () {
    test('BOM, header, CRLF, oldest first, deleted skipped', () {
      final csv = ExpenseCsvBuilder.build([
        expenseOf(amount: 20, date: DateTime(2026, 11, 2), title: 'Chai'),
        expenseOf(amount: 5, date: DateTime(2026, 11, 1), title: 'Old'),
        expenseOf(
          amount: 9,
          date: DateTime(2026, 11, 3),
          title: 'Gone',
          isDeleted: true,
        ),
      ]);
      expect(csv.startsWith('﻿Date,Title,'), isTrue);
      final lines = csv.substring(1).trimRight().split('\r\n');
      expect(lines.length, 3);
      expect(lines[1], startsWith('2026-11-01,Old,'));
      expect(lines[2], startsWith('2026-11-02,Chai,'));
      expect(csv.contains('Gone'), isFalse);
    });

    test('quotes commas, quotes and newlines', () {
      final csv = ExpenseCsvBuilder.build([
        expenseOf(
          amount: 1,
          date: DateTime(2026, 1, 1),
          title: 'Dinner, "family"\nnight',
        ),
      ]);
      expect(csv, contains('"Dinner, ""family""\nnight"'));
    });

    test('neutralises formula injection in text cells', () {
      final csv = ExpenseCsvBuilder.build([
        expenseOf(
          amount: 1,
          date: DateTime(2026, 1, 1),
          title: '=HYPERLINK("x")',
          merchant: '@evil',
        ),
      ]);
      expect(csv, contains("'=HYPERLINK"));
      expect(csv, contains("'@evil"));
    });

    test('keeps unicode and tax section', () {
      final csv = ExpenseCsvBuilder.build([
        expenseOf(
          amount: 12000,
          date: DateTime(2026, 5, 1),
          title: 'एलआयसी हप्ता',
          taxTag: '80C',
          paymentMethod: 'UPI',
        ),
      ]);
      expect(csv, contains('एलआयसी हप्ता'));
      expect(csv, contains('12000.00'));
      expect(csv, contains(',UPI,80C,'));
    });

    test('tax summary CSV has per-section totals', () {
      final summary = GetTaxSummaryUseCase.compute([
        expenseOf(amount: 160000, date: DateTime(2026, 5, 1), taxTag: '80C'),
      ], const FinancialYear(2026));
      final csv = ExpenseCsvBuilder.buildTaxSummary(summary);
      expect(csv, contains('FY 2026-27'));
      expect(csv, contains('80C total,,,Limit 150000.00,160000.00'));
      expect(csv, contains('Estimated deductible,,,,150000.00'));
    });
  });

  group('MonthlyStatement', () {
    final all = [
      expenseOf(amount: 100, date: DateTime(2026, 10, 15)),
      expenseOf(
        amount: 300,
        date: DateTime(2026, 11, 2),
        categoryId: 'bills',
        paymentMethod: 'UPI',
        taxTag: 'HRA',
      ),
      expenseOf(amount: 50, date: DateTime(2026, 11, 5), paymentMethod: 'Cash'),
      expenseOf(amount: 50, date: DateTime(2026, 11, 6)),
      expenseOf(amount: 999, date: DateTime(2026, 11, 7), isDeleted: true),
      expenseOf(amount: 70, date: DateTime(2026, 12, 1)),
    ];

    test('totals, groups and comparison', () {
      final s = MonthlyStatement.compute(all, DateTime(2026, 11, 20));
      expect(s.month, DateTime(2026, 11));
      expect(s.expenses.length, 3);
      expect(s.total, 400);
      expect(s.previousMonthTotal, 100);
      expect(s.changeVsPreviousMonth, closeTo(3.0, 1e-9));
      expect(s.byCategory.first.key, 'bills');
      expect(s.byCategory[1].count, 2);
      expect(s.byPaymentMethod.map((l) => l.key), ['UPI', 'Cash', 'Other']);
      expect(s.taxTaggedTotal, 300);
      expect(s.largest!.amount, 300);
    });

    test('average per day uses elapsed days for the current month', () {
      final s = MonthlyStatement.compute(all, DateTime(2026, 11));
      expect(s.averagePerDay(DateTime(2026, 11, 10)), 40);
      expect(s.averagePerDay(DateTime(2027, 1, 1)), closeTo(400 / 30, 1e-9));
    });

    test('empty month', () {
      final s = MonthlyStatement.compute(all, DateTime(2026, 6));
      expect(s.isEmpty, isTrue);
      expect(s.largest, isNull);
      expect(s.changeVsPreviousMonth, isNull);
    });
  });

  test('export range bounds', () {
    final now = DateTime(2026, 1, 15);
    final (s1, e1, l1) = ExportExpensesCsvUseCase.bounds(
      ExportRange.lastMonth,
      now,
    );
    expect((s1, e1, l1), (DateTime(2025, 12), DateTime(2026, 1), '2025-12'));
    final (s2, e2, l2) = ExportExpensesCsvUseCase.bounds(
      ExportRange.financialYear,
      now,
    );
    expect((s2, e2, l2), (DateTime(2025, 4), DateTime(2026, 4), 'fy_2025-26'));
    final (s3, e3, _) = ExportExpensesCsvUseCase.bounds(
      ExportRange.allTime,
      now,
    );
    expect((s3, e3), (null, null));
  });

  test('PDF renders unicode, ₹ and emoji without throwing', () async {
    final statement = MonthlyStatement.compute([
      for (var i = 0; i < 60; i++)
        expenseOf(
          amount: 100.0 + i,
          date: DateTime(2026, 11, 1 + i % 28),
          title: i.isEven ? 'चहा ☕ $i' : 'Swiggy 🍕 order $i',
          merchant: 'दुकान',
          paymentMethod: i % 3 == 0 ? 'UPI' : 'Cash',
          taxTag: i == 0 ? TaxSection.s80C.code : null,
        ),
    ], DateTime(2026, 11));
    final bytes = await PdfStatementRenderer(
      now: () => DateTime(2026, 11, 30),
    ).render(statement);
    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    expect(bytes.length, greaterThan(10000));
  });
}
