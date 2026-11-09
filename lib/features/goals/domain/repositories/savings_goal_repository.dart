import '../entities/savings_goal.dart';

abstract class SavingsGoalRepository {
  Future<List<SavingsGoal>> getAll();
  Future<SavingsGoal?> getById(String id);
  Future<void> save(SavingsGoal goal);
  Future<void> delete(String id);
  Stream<void> watch();
}
