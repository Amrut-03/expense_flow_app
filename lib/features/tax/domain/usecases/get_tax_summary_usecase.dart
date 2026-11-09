import 'dart:math' as math;

import 'package:equatable/equatable.dart';

import '../../../expense/domain/entities/expense_entity.dart';
import '../../../expense/domain/repositories/expense_repository.dart';
import '../entities/tax_section.dart';

class TaxSectionTotal extends Equatable {
  final TaxSection section;
  final double total;
  final List<ExpenseEntity> expenses;

  const TaxSectionTotal({
    required this.section,
    required this.total,
    required this.expenses,
  });

  /// Amount that counts towards the deduction (capped where a cap exists).
  double get claimable {
    final cap = section.cap;
    return cap == null ? total : math.min(total, cap);
  }

  /// Unused room under the cap, or `null` when uncapped.
  double? get remainingCap {
    final cap = section.cap;
    return cap == null ? null : math.max(0, cap - total);
  }

  @override
  List<Object?> get props => [section, total, expenses];
}

class TaxSummary extends Equatable {
  final FinancialYear year;

  /// One entry per section that has at least one tagged expense, in
  /// [TaxSection] order.
  final List<TaxSectionTotal> sections;

  const TaxSummary({required this.year, required this.sections});

  double get totalClaimable =>
      sections.fold(0, (sum, s) => sum + s.claimable);

  bool get isEmpty => sections.isEmpty;

  @override
  List<Object?> get props => [year, sections];
}

/// Totals tax-tagged expenses for one Indian financial year.
class GetTaxSummaryUseCase {
  const GetTaxSummaryUseCase(this.repository);

  final ExpenseRepository repository;

  Future<TaxSummary> call(FinancialYear year) async {
    return compute(await repository.getExpenses(), year);
  }

  static TaxSummary compute(List<ExpenseEntity> expenses, FinancialYear year) {
    final bySection = <TaxSection, List<ExpenseEntity>>{};

    for (final e in expenses) {
      if (e.isDeleted || !year.contains(e.date)) continue;
      final section = TaxSection.fromCode(e.taxTag);
      if (section == null) continue;
      bySection.putIfAbsent(section, () => []).add(e);
    }

    return TaxSummary(
      year: year,
      sections: [
        for (final section in TaxSection.values)
          if (bySection[section] case final list?)
            TaxSectionTotal(
              section: section,
              total: list.fold(0, (sum, e) => sum + e.amount),
              expenses: list..sort((a, b) => a.date.compareTo(b.date)),
            ),
      ],
    );
  }
}
