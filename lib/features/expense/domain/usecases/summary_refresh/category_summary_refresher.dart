import 'package:expense_flow_app/core/constants/category_label.dart';
import 'package:expense_flow_app/core/utils/summary_dates.dart';
import 'package:expense_flow_app/features/ai/domain/entities/chunk_inputs.dart';
import 'package:expense_flow_app/features/ai/domain/services/chunk_generators/category_summary_chunk_generator.dart';
import 'package:expense_flow_app/features/expense/domain/entities/expense_entity.dart';
import 'package:expense_flow_app/features/expense/domain/repositories/expense_repository.dart';

import 'summary_chunk_refresher.dart';

/// Recomputes a `category-<categoryId>-YYYY-MM` summary chunk for every
/// category and month that has at least one visible expense.
///
/// Backfills the category-level index for the full history so retrieval can
/// answer questions such as "how much did I spend on food last month?" even
/// for months that predate the AI feature.
class CategorySummaryRefresher implements SummaryChunkRefresher {
  final ExpenseRepository expenseRepository;
  final CategorySummaryChunkGenerator generator;

  const CategorySummaryRefresher({
    required this.expenseRepository,
    required this.generator,
  });

  @override
  Future<List<DesiredChunk>> refresh() async {
    final all = await expenseRepository.getExpenses();
    final visible = all.where((e) => !e.isDeleted).toList();

    final keys = visible.map((e) => (categoryId: e.categoryId, month: _monthOf(e.date))).toSet();

    return [
      for (final key in keys)
        _categoryChunk(
          key.categoryId,
          key.month,
          expenses: visible.where(
            (e) => e.categoryId == key.categoryId && SummaryDates.sameMonth(e.date, key.month),
          ),
        ),
    ];
  }

  DesiredChunk _categoryChunk(
    String categoryId,
    DateTime month, {
    required Iterable<ExpenseEntity> expenses,
  }) {
    final categoryExpenses = expenses.toList();

    final input = CategorySummaryChunkInput(
      id: 'category-$categoryId-${SummaryDates.yyyymm(month)}',
      categoryName: CategoryLabels.labelOf(categoryId),
      totalSpent: _sum(categoryExpenses),
      transactionCount: categoryExpenses.length,
      periodStart: month,
      periodEnd: DateTime(month.year, month.month + 1, 0),
    );

    return DesiredChunk(
      id: input.id,
      chunkType: generator.chunkType,
      text: generator.generate(input),
      sourceId: input.id,
    );
  }

  DateTime _monthOf(DateTime date) => DateTime(date.year, date.month);

  double _sum(Iterable<ExpenseEntity> expenses) {
    return expenses.fold(0.0, (sum, e) => sum + e.amount);
  }
}
