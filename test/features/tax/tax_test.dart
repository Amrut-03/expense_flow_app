import 'package:expense_flow_app/features/ai/domain/entities/chunk_inputs.dart';
import 'package:expense_flow_app/features/ai/domain/services/chunk_generators/transaction_chunk_generator.dart';
import 'package:expense_flow_app/features/expense/data/models/expense_model.dart';
import 'package:expense_flow_app/features/tax/domain/entities/tax_section.dart';
import 'package:expense_flow_app/features/tax/domain/services/tax_tag_suggester.dart';
import 'package:expense_flow_app/features/tax/domain/usecases/get_tax_summary_usecase.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/expense_factory.dart';

void main() {
  group('FinancialYear', () {
    test('April starts a new year, March belongs to the previous one', () {
      expect(FinancialYear.of(DateTime(2026, 4, 1)).startYear, 2026);
      expect(FinancialYear.of(DateTime(2026, 3, 31)).startYear, 2025);
      expect(FinancialYear.of(DateTime(2027, 1, 15)).startYear, 2026);
    });

    test('label and bounds', () {
      const fy = FinancialYear(2026);
      expect(fy.label, 'FY 2026-27');
      expect(fy.contains(DateTime(2026, 4, 1)), isTrue);
      expect(fy.contains(DateTime(2027, 3, 31, 23, 59)), isTrue);
      expect(fy.contains(DateTime(2027, 4, 1)), isFalse);
      expect(const FinancialYear(2099).label, 'FY 2099-00');
    });
  });

  group('TaxTagSuggester', () {
    TaxSection? s(String text) => TaxTagSuggester.suggest(title: text);

    test('matches unambiguous phrases', () {
      expect(s('LIC premium'), TaxSection.s80C);
      expect(s('School fees for Aarav'), TaxSection.s80C);
      expect(s('Star Health renewal'), TaxSection.s80D);
      expect(s('House rent November'), TaxSection.hra);
      expect(s('Donation to temple trust'), TaxSection.s80G);
      expect(s('Education loan EMI'), TaxSection.s80E);
    });

    test('specific sections beat generic ones', () {
      expect(s('Health insurance'), TaxSection.s80D);
      expect(s('student loan interest'), TaxSection.s80E);
    });

    test('ignores everyday spending and partial words', () {
      expect(s('Taxi to airport'), isNull);
      expect(s('Rental car'), isNull);
      expect(s('Click Ltd'), isNull, reason: '"lic" inside a word');
      expect(s('Swiggy dinner'), isNull);
      expect(TaxTagSuggester.suggest(), isNull);
    });

    test('looks at merchant and note too', () {
      expect(
        TaxTagSuggester.suggest(title: 'Monthly', merchant: 'Niva Bupa'),
        TaxSection.s80D,
      );
      expect(
        TaxTagSuggester.suggest(title: 'Transfer', note: 'PPF deposit'),
        TaxSection.s80C,
      );
    });
  });

  group('GetTaxSummaryUseCase.compute', () {
    const fy = FinancialYear(2026);

    test('groups by section, filters by year and skips deleted', () {
      final summary = GetTaxSummaryUseCase.compute([
        expenseOf(amount: 50000, date: DateTime(2026, 5, 1), taxTag: '80C'),
        expenseOf(amount: 20000, date: DateTime(2027, 2, 1), taxTag: '80C'),
        expenseOf(amount: 9999, date: DateTime(2026, 3, 31), taxTag: '80C'),
        expenseOf(
          amount: 1000,
          date: DateTime(2026, 6, 1),
          taxTag: '80C',
          isDeleted: true,
        ),
        expenseOf(amount: 15000, date: DateTime(2026, 7, 1), taxTag: 'HRA'),
        expenseOf(amount: 300, date: DateTime(2026, 7, 2)),
        expenseOf(amount: 10, date: DateTime(2026, 7, 3), taxTag: 'bogus'),
      ], fy);

      expect(summary.sections.map((s) => s.section), [
        TaxSection.s80C,
        TaxSection.hra,
      ]);
      final c = summary.sections.first;
      expect(c.total, 70000);
      expect(c.expenses.length, 2);
      expect(c.expenses.first.date, DateTime(2026, 5, 1), reason: 'sorted');
      expect(c.remainingCap, 80000);
      expect(summary.totalClaimable, 85000);
    });

    test('caps the claimable amount at the statutory limit', () {
      final summary = GetTaxSummaryUseCase.compute([
        expenseOf(amount: 120000, date: DateTime(2026, 5, 1), taxTag: '80C'),
        expenseOf(amount: 60000, date: DateTime(2026, 9, 1), taxTag: '80C'),
        expenseOf(amount: 30000, date: DateTime(2026, 9, 1), taxTag: '80D'),
      ], fy);

      final c = summary.sections[0];
      final d = summary.sections[1];
      expect(c.claimable, 150000);
      expect(c.remainingCap, 0);
      expect(d.claimable, 25000);
      expect(summary.totalClaimable, 175000);
    });

    test('empty when nothing is tagged', () {
      final summary = GetTaxSummaryUseCase.compute([
        expenseOf(amount: 100, date: DateTime(2026, 5, 1)),
      ], fy);
      expect(summary.isEmpty, isTrue);
      expect(summary.totalClaimable, 0);
    });
  });

  group('tax tag persistence', () {
    test('survives entity → model → JSON → entity', () {
      final e = expenseOf(
        amount: 500,
        date: DateTime(2026, 5, 1),
        taxTag: '80D',
      );
      final back = ExpenseModel.fromJson(
        ExpenseModel.fromEntity(e).toJson(),
      ).toEntity();
      expect(back.taxTag, '80D');
    });

    test('copyWith keeps the tag unless cleared', () {
      final e = expenseOf(amount: 1, date: DateTime(2026), taxTag: '80G');
      expect(e.copyWith(amount: 2).taxTag, '80G');
      expect(e.copyWith(clearTaxTag: true).taxTag, isNull);
    });
  });

  test('transaction chunk mentions the tax section', () {
    final text = TransactionChunkGenerator().generate(
      TransactionChunkInput(
        id: '1',
        merchant: 'LIC',
        categoryName: 'Bills',
        amount: 12000,
        date: DateTime(2026, 5, 1),
        taxSection: '80C',
      ),
    );
    expect(text, contains('section 80C'));
  });
}
