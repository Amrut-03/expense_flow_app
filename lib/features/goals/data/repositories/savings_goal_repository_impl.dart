import 'package:hive/hive.dart';

import '../../domain/entities/savings_goal.dart';
import '../../domain/repositories/savings_goal_repository.dart';

/// Goals live in an encrypted Hive box as `id -> SavingsGoal.toMap()`.
/// Local-only for now.
class SavingsGoalRepositoryImpl implements SavingsGoalRepository {
  SavingsGoalRepositoryImpl(this.box);

  final Box<dynamic> box;

  @override
  Future<List<SavingsGoal>> getAll() async =>
      box.values.map(SavingsGoal.fromMap).whereType<SavingsGoal>().toList();

  @override
  Future<SavingsGoal?> getById(String id) async =>
      SavingsGoal.fromMap(box.get(id));

  @override
  Future<void> save(SavingsGoal goal) => box.put(goal.id, goal.toMap());

  @override
  Future<void> delete(String id) => box.delete(id);

  @override
  Stream<void> watch() => box.watch().map((_) {});
}
