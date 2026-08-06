import 'package:expense_flow_app/core/constants/category_label.dart';
import 'package:expense_flow_app/features/ai/domain/entities/chunk_inputs.dart';
import 'package:expense_flow_app/features/ai/domain/services/chunk_generators/budget_chunk_generator.dart';
import 'package:expense_flow_app/features/budget/domain/entities/budget_entity.dart';
import 'package:expense_flow_app/features/budget/domain/repositories/budget_repository.dart';
import 'package:expense_flow_app/features/expense/domain/entities/expense_entity.dart';
import 'package:expense_flow_app/features/expense/domain/repositories/expense_repository.dart';

import 'summary_chunk_refresher.dart';

/// Recomputes a `budget-<categoryId>` chunk for every category that has an
/// active budget, counting spending within that budget's period.
class BudgetSummaryRefresher implements SummaryChunkRefresher {
  final BudgetRepository budgetRepository;
  final ExpenseRepository expenseRepository;
  final BudgetChunkGenerator generator;
  final DateTime Function() clock;

  const BudgetSummaryRefresher({
    required this.budgetRepository,
    required this.expenseRepository,
    required this.generator,
    this.clock = DateTime.now,
  });

  @override
  Future<List<DesiredChunk>> refresh() async {
    final limits = await budgetRepository.getLimits();
    final periods = await budgetRepository.getPeriods();

    final all = await expenseRepository.getExpenses();
    final visible = all.where((e) => !e.isDeleted).toList();

    final chunks = <DesiredChunk>[];

    limits.forEach((categoryId, limit) {
      if (limit <= 0) return;

      final period = periods[categoryId] ?? BudgetPeriod.monthly;
      if (period == BudgetPeriod.noLimit) return;

      final window = _periodWindow(clock(), period);
      final spent = _sum(
        visible.where(
          (e) =>
              e.categoryId == categoryId &&
              !e.date.isBefore(window.start) &&
              e.date.isBefore(window.end),
        ),
      );

      final input = BudgetChunkInput(
        id: 'budget-$categoryId',
        categoryName: CategoryLabels.labelOf(categoryId),
        spent: spent,
        limit: limit,
        period: period.name,
      );

      chunks.add(
        DesiredChunk(
          id: input.id,
          chunkType: generator.chunkType,
          text: generator.generate(input),
          sourceId: input.id,
        ),
      );
    });

    return chunks;
  }

  _Window _periodWindow(DateTime now, BudgetPeriod period) {
    switch (period) {
      case BudgetPeriod.monthly:
        return _Window(
          DateTime(now.year, now.month),
          DateTime(now.year, now.month + 1),
        );
      case BudgetPeriod.quarterly:
        final quarterStartMonth = ((now.month - 1) ~/ 3) * 3 + 1;

        return _Window(
          DateTime(now.year, quarterStartMonth),
          DateTime(now.year, quarterStartMonth + 3),
        );
      case BudgetPeriod.yearly:
        return _Window(DateTime(now.year, 1), DateTime(now.year + 1, 1));
      case BudgetPeriod.noLimit:
        return _Window(now, now);
    }
  }

  double _sum(Iterable<ExpenseEntity> expenses) {
    return expenses.fold(0.0, (sum, e) => sum + e.amount);
  }
}

class _Window {
  final DateTime start;
  final DateTime end;

  const _Window(this.start, this.end);
}
