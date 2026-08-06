import 'package:expense_flow_app/core/constants/category_label.dart';
import 'package:expense_flow_app/core/utils/summary_dates.dart';
import 'package:expense_flow_app/features/ai/domain/entities/chunk_inputs.dart';
import 'package:expense_flow_app/features/ai/domain/usecases/regenerate_transaction_chunks_usecase.dart';

import '../entities/expense_entity.dart';
import '../repositories/expense_repository.dart';

/// Keeps the AI retrieval index in sync with the transaction feature.
///
/// After a transaction is added, edited, or deleted this use case
/// recomputes the monthly, weekly, and category summaries around that
/// transaction and delegates the actual chunk (re)generation to the AI
/// module. The AI module stays independent: all data crosses the boundary
/// as neutral inputs defined by the AI module.
class RegenerateAiChunksUseCase {
  final ExpenseRepository expenseRepository;
  final RegenerateTransactionChunksUseCase regenerateTransactionChunks;

  const RegenerateAiChunksUseCase({
    required this.expenseRepository,
    required this.regenerateTransactionChunks,
  });

  Future<void> call(String expenseId) async {
    final expense = await expenseRepository.getExpenseById(expenseId);

    if (expense == null) return;

    final all = await expenseRepository.getExpenses();
    final visible = all.where((e) => !e.isDeleted).toList();

    final month = DateTime(expense.date.year, expense.date.month);
    final weekStart = SummaryDates.startOfWeek(expense.date);
    final weekEnd = weekStart.add(const Duration(days: 6));
    final previousMonth = DateTime(month.year, month.month - 1);
    final previousWeekStart = weekStart.subtract(const Duration(days: 7));
    final previousWeekEnd = weekStart.subtract(const Duration(days: 1));

    final monthExpenses = visible
        .where((e) => SummaryDates.sameMonth(e.date, month))
        .toList();
    final weekExpenses = visible
        .where((e) => !e.date.isBefore(weekStart) && !e.date.isAfter(weekEnd))
        .toList();
    final categoryExpenses = visible
        .where(
          (e) =>
              e.categoryId == expense.categoryId &&
              SummaryDates.sameMonth(e.date, month),
        )
        .toList();

    final transaction = expense.isDeleted
        ? null
        : TransactionChunkInput(
            id: expense.id,
            merchant: _merchant(expense),
            categoryName: _categoryLabel(expense.categoryId),
            amount: expense.amount,
            date: expense.date,
            note: expense.note,
          );

    final previousMonthSpent = _sum(
      visible.where((e) => SummaryDates.sameMonth(e.date, previousMonth)),
    );
    final previousWeekSpent = _sum(
      visible.where(
        (e) =>
            !e.date.isBefore(previousWeekStart) &&
            !e.date.isAfter(previousWeekEnd),
      ),
    );

    await regenerateTransactionChunks(
      TransactionChunkRegenerationInput(
        transactionId: expense.id,
        transaction: transaction,
        monthlySummary: MonthlySummaryChunkInput(
          id: 'monthly-${SummaryDates.yyyymm(month)}',
          month: month,
          totalSpent: _sum(monthExpenses),
          transactionCount: monthExpenses.length,
          previousMonthSpent: previousMonthSpent == 0
              ? null
              : previousMonthSpent,
        ),
        weeklySummary: WeeklySummaryChunkInput(
          id: 'weekly-${SummaryDates.yyyymmdd(weekStart)}',
          weekStart: weekStart,
          weekEnd: weekEnd,
          totalSpent: _sum(weekExpenses),
          transactionCount: weekExpenses.length,
          previousWeekSpent: previousWeekSpent == 0 ? null : previousWeekSpent,
        ),
        categorySummary: CategorySummaryChunkInput(
          id: 'category-${expense.categoryId}-${SummaryDates.yyyymm(month)}',
          categoryName: _categoryLabel(expense.categoryId),
          totalSpent: _sum(categoryExpenses),
          transactionCount: categoryExpenses.length,
          periodStart: month,
          periodEnd: DateTime(month.year, month.month + 1, 0),
        ),
      ),
    );
  }

  String _merchant(ExpenseEntity expense) {
    final title = expense.title?.trim();

    if (title != null && title.isNotEmpty) return title;

    return _categoryLabel(expense.categoryId);
  }

  String _categoryLabel(String categoryId) {
    return CategoryLabels.labelOf(categoryId);
  }

  double _sum(Iterable<ExpenseEntity> expenses) {
    return expenses.fold(0.0, (sum, e) => sum + e.amount);
  }
}
