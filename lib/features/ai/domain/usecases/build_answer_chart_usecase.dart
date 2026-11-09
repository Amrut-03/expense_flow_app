import '../../../budget/domain/usecases/get_budget_insights_usecase.dart';
import '../../../expense/domain/repositories/expense_repository.dart';
import '../entities/answer_chart.dart';
import '../services/answer_chart_planner.dart';

/// Builds the optional chart shown under an AI answer.
class BuildAnswerChartUseCase {
  BuildAnswerChartUseCase({
    required this.expenseRepository,
    required this.budgetInsights,
    required this.categoryNames,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final ExpenseRepository expenseRepository;
  final GetBudgetInsightsUseCase budgetInsights;

  /// Category id → names the user might type (all app languages).
  final Map<String, List<String>> Function() categoryNames;
  final DateTime Function() _now;

  Future<AnswerChart?> call(String question) async {
    final insights = await budgetInsights();
    return AnswerChartPlanner.plan(
      question: question,
      expenses: await expenseRepository.getExpenses(),
      now: _now(),
      budgetLimits: {for (final b in insights.budgets) b.categoryId: b.limit},
      budgetSpent: {for (final b in insights.budgets) b.categoryId: b.spent},
      categoryNames: categoryNames(),
    );
  }
}
