import '../entities/expense_entity.dart';
import '../repositories/expense_repository.dart';

class GetExpensesUseCase {
  final ExpenseRepository repository;

  const GetExpensesUseCase(this.repository);

  Future<List<ExpenseEntity>> call() {
    return repository.getExpenses();
  }
}
