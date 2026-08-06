import '../entities/budget_entity.dart';

abstract class BudgetRepository {
  Future<Map<String, double>> getLimits();
  Future<Map<String, BudgetPeriod>> getPeriods();
  Future<void> setLimits(Map<String, double> limits);
  Future<void> setPeriods(Map<String, BudgetPeriod> periods);
  Future<void> setAll(
    Map<String, double> limits,
    Map<String, BudgetPeriod> periods,
  );
}
