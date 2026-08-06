import '../entities/budget_entity.dart';
import '../repositories/budget_repository.dart';

class SetBudgetLimitsUseCase {
  final BudgetRepository repository;

  SetBudgetLimitsUseCase({required this.repository});

  Future<void> call(
    Map<String, double> limits, {
    Map<String, BudgetPeriod> periods = const {},
  }) => repository.setAll(limits, periods);
}
