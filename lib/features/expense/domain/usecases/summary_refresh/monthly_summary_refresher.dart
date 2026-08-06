import 'package:expense_flow_app/core/utils/summary_dates.dart';
import 'package:expense_flow_app/features/ai/domain/entities/chunk_inputs.dart';
import 'package:expense_flow_app/features/ai/domain/services/chunk_generators/monthly_summary_chunk_generator.dart';
import 'package:expense_flow_app/features/expense/domain/entities/expense_entity.dart';
import 'package:expense_flow_app/features/expense/domain/repositories/expense_repository.dart';

import 'summary_chunk_refresher.dart';

/// Recomputes a `monthly-YYYY-MM` summary chunk for every month that has at
/// least one visible expense.
class MonthlySummaryRefresher implements SummaryChunkRefresher {
  final ExpenseRepository expenseRepository;
  final MonthlySummaryChunkGenerator generator;

  const MonthlySummaryRefresher({
    required this.expenseRepository,
    required this.generator,
  });

  @override
  Future<List<DesiredChunk>> refresh() async {
    final all = await expenseRepository.getExpenses();
    final visible = all.where((e) => !e.isDeleted).toList();

    final months = visible.map((e) => _monthOf(e.date)).toSet().toList()
      ..sort((a, b) => a.compareTo(b));

    return [
      for (final month in months)
        _monthChunk(
          month,
          monthExpenses: _inMonth(visible, month),
          visible: visible,
        ),
    ];
  }

  DesiredChunk _monthChunk(
    DateTime month, {
    required List<ExpenseEntity> monthExpenses,
    required List<ExpenseEntity> visible,
  }) {
    final previousMonth = DateTime(month.year, month.month - 1);
    final previousSpent = _sum(_inMonth(visible, previousMonth));

    final input = MonthlySummaryChunkInput(
      id: 'monthly-${SummaryDates.yyyymm(month)}',
      month: month,
      totalSpent: _sum(monthExpenses),
      transactionCount: monthExpenses.length,
      previousMonthSpent: previousSpent == 0 ? null : previousSpent,
    );

    return DesiredChunk(
      id: input.id,
      chunkType: generator.chunkType,
      text: generator.generate(input),
      sourceId: input.id,
    );
  }

  List<ExpenseEntity> _inMonth(List<ExpenseEntity> source, DateTime month) {
    return source.where((e) => SummaryDates.sameMonth(e.date, month)).toList();
  }

  DateTime _monthOf(DateTime date) => DateTime(date.year, date.month);

  double _sum(Iterable<ExpenseEntity> expenses) {
    return expenses.fold(0.0, (sum, e) => sum + e.amount);
  }
}
