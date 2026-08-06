import '../repositories/budget_repository.dart';

class GetBudgetLimitsUseCase {
  final BudgetRepository repository;

  GetBudgetLimitsUseCase({required this.repository});

  Future<Map<String, double>> call() => repository.getLimits();
}
