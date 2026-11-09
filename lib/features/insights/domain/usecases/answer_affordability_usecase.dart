import '../../../budget/domain/usecases/get_budget_insights_usecase.dart';
import '../../../expense/domain/repositories/expense_repository.dart';
import '../../../goals/domain/repositories/savings_goal_repository.dart';
import '../services/affordability.dart';

/// "Can I afford it?" mode for the assistant. Returns `null` when the
/// question isn't about affordability so the normal RAG pipeline answers.
class AnswerAffordabilityUseCase {
  AnswerAffordabilityUseCase({
    required this.insights,
    required this.expenseRepository,
    required this.goalRepository,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final GetBudgetInsightsUseCase insights;
  final ExpenseRepository expenseRepository;
  final SavingsGoalRepository goalRepository;
  final DateTime Function() _now;

  Future<String?> call(String question) async {
    if (!AffordabilityQuestion.matches(question)) return null;
    final expenses = (await expenseRepository.getExpenses())
        .where((e) => !e.isDeleted)
        .toList();
    final parsed = AffordabilityQuestion.parse(question, history: expenses);
    if (parsed == null) return null;

    return AffordabilityAdvisor.answer(
      question: parsed,
      insights: await insights(),
      expenses: expenses,
      goals: await goalRepository.getAll(),
      now: _now(),
    );
  }
}
