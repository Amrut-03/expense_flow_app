import '../../domain/entities/expense_entity.dart';
import '../../domain/repositories/expense_repository.dart';
import '../datasources/local/expense_local_datasource_impl.dart';
import '../models/expense_model.dart';

class ExpenseRepositoryImpl implements ExpenseRepository {
  final ExpenseLocalDataSource localDataSource;

  ExpenseRepositoryImpl({required this.localDataSource});

  @override
  Future<void> addExpense(ExpenseEntity expense) async {
    final model = ExpenseModel.fromEntity(expense);

    await localDataSource.addExpense(model);
  }

  @override
  Future<List<ExpenseEntity>> getExpenses() async {
    final models = await localDataSource.getExpenses();

    return models.map((e) => e.toEntity()).toList();
  }

  @override
  Future<void> updateExpense(ExpenseEntity expense) async {
    final model = ExpenseModel.fromEntity(expense);

    await localDataSource.updateExpense(model);
  }

  @override
  Future<void> deleteExpense(String id) async {
    await localDataSource.deleteExpense(id);
  }

  @override
  Future<ExpenseEntity?> getExpenseById(String id) async {
    final model = await localDataSource.getExpenseById(id);

    return model?.toEntity();
  }
}
