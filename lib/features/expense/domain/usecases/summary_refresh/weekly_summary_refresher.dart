import 'package:expense_flow_app/core/utils/summary_dates.dart';
import 'package:expense_flow_app/features/ai/domain/entities/chunk_inputs.dart';
import 'package:expense_flow_app/features/ai/domain/services/chunk_generators/weekly_summary_chunk_generator.dart';
import 'package:expense_flow_app/features/expense/domain/entities/expense_entity.dart';
import 'package:expense_flow_app/features/expense/domain/repositories/expense_repository.dart';

import 'summary_chunk_refresher.dart';

/// Recomputes a `weekly-YYYY-MM-DD` summary chunk for every week that has at
/// least one visible expense.
///
/// Historically weekly chunks were only produced when a transaction in that
/// week was added, edited, or deleted. This refresher backfills every week so
/// retrieval can answer questions about any week's spending.
class WeeklySummaryRefresher implements SummaryChunkRefresher {
  final ExpenseRepository expenseRepository;
  final WeeklySummaryChunkGenerator generator;

  const WeeklySummaryRefresher({
    required this.expenseRepository,
    required this.generator,
  });

  @override
  Future<List<DesiredChunk>> refresh() async {
    final all = await expenseRepository.getExpenses();
    final visible = all.where((e) => !e.isDeleted).toList();

    final weekStarts = visible.map((e) => SummaryDates.startOfWeek(e.date)).toSet()
      ..toList().sort((a, b) => a.compareTo(b));

    return [
      for (final weekStart in weekStarts)
        _weekChunk(
          weekStart,
          weekExpenses: _inWeek(visible, weekStart),
          visible: visible,
        ),
    ];
  }

  DesiredChunk _weekChunk(
    DateTime weekStart, {
    required List<ExpenseEntity> weekExpenses,
    required List<ExpenseEntity> visible,
  }) {
    final previousStart = weekStart.subtract(const Duration(days: 7));
    final previousSpent = _sum(_inWeek(visible, previousStart));

    final input = WeeklySummaryChunkInput(
      id: 'weekly-${SummaryDates.yyyymmdd(weekStart)}',
      weekStart: weekStart,
      weekEnd: weekStart.add(const Duration(days: 6)),
      totalSpent: _sum(weekExpenses),
      transactionCount: weekExpenses.length,
      previousWeekSpent: previousSpent == 0 ? null : previousSpent,
    );

    return DesiredChunk(
      id: input.id,
      chunkType: generator.chunkType,
      text: generator.generate(input),
      sourceId: input.id,
    );
  }

  List<ExpenseEntity> _inWeek(List<ExpenseEntity> source, DateTime weekStart) {
    final weekEnd = weekStart.add(const Duration(days: 6));
    return source
        .where((e) => !e.date.isBefore(weekStart) && !e.date.isAfter(weekEnd))
        .toList();
  }

  double _sum(Iterable<ExpenseEntity> expenses) {
    return expenses.fold(0.0, (sum, e) => sum + e.amount);
  }
}
