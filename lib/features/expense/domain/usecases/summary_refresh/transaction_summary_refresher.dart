import 'package:expense_flow_app/core/constants/category_label.dart';
import 'package:expense_flow_app/features/ai/domain/entities/chunk_inputs.dart';
import 'package:expense_flow_app/features/ai/domain/services/chunk_generators/transaction_chunk_generator.dart';
import 'package:expense_flow_app/features/expense/domain/entities/expense_entity.dart';
import 'package:expense_flow_app/features/expense/domain/repositories/expense_repository.dart';

import 'summary_chunk_refresher.dart';

/// Recomputes a `transaction-<id>` chunk for every visible expense.
///
/// This is the full-history counterpart of the write-time regeneration in
/// `RegenerateAiChunksUseCase`: it guarantees pre-existing expenses that were
/// never added through a change event are still indexed, so retrieval can
/// answer questions about any single transaction.
class TransactionSummaryRefresher implements SummaryChunkRefresher {
  final ExpenseRepository expenseRepository;
  final TransactionChunkGenerator generator;

  const TransactionSummaryRefresher({
    required this.expenseRepository,
    required this.generator,
  });

  @override
  Future<List<DesiredChunk>> refresh() async {
    final all = await expenseRepository.getExpenses();
    final visible = all.where((e) => !e.isDeleted).toList();

    return [
      for (final expense in visible) _chunk(expense),
    ];
  }

  DesiredChunk _chunk(ExpenseEntity expense) {
    final input = TransactionChunkInput(
      id: expense.id,
      merchant: _merchant(expense),
      categoryName: CategoryLabels.labelOf(expense.categoryId),
      amount: expense.amount,
      date: expense.date,
      note: expense.note,
    );

    return DesiredChunk(
      id: 'transaction-${expense.id}',
      chunkType: generator.chunkType,
      text: generator.generate(input),
      sourceId: expense.id,
    );
  }

  String _merchant(ExpenseEntity expense) {
    final title = expense.title?.trim();

    if (title != null && title.isNotEmpty) return title;

    return CategoryLabels.labelOf(expense.categoryId);
  }
}
