import '../entities/budget_entity.dart';
import '../repositories/budget_repository.dart';

class GetBudgetPeriodsUseCase {
  final BudgetRepository repository;

  GetBudgetPeriodsUseCase({required this.repository});

  Future<Map<String, BudgetPeriod>> call() => repository.getPeriods();
}
