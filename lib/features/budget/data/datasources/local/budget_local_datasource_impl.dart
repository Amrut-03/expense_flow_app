import 'package:hive/hive.dart';
import '../../models/budget_model.dart';

abstract class BudgetLocalDataSource {
  Future<List<BudgetModel>> getAll();
  Future<void> saveAll(List<BudgetModel> budgets);
}

class BudgetLocalDataSourceImpl implements BudgetLocalDataSource {
  final Box<BudgetModel> box;

  BudgetLocalDataSourceImpl(this.box);

  @override
  Future<List<BudgetModel>> getAll() async {
    return box.values.toList();
  }

  @override
  Future<void> saveAll(List<BudgetModel> budgets) async {
    await box.clear();
    for (final b in budgets) {
      await box.put(b.categoryId, b);
    }
  }
}
