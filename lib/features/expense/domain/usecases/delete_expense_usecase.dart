import '../entities/expense_entity.dart';
import '../repositories/expense_repository.dart';

class DeleteExpenseUseCase {
  final ExpenseRepository repository;
  DeleteExpenseUseCase(this.repository);

  Future<void> call(String id) async {
    final expense = await repository.getExpenseById(id);

    if (expense == null) return;

    await repository.updateExpense(
      expense.copyWith(
        isDeleted: true,
        syncStatus: SyncStatus.pending,
        version: expense.version + 1,
        updatedAt: DateTime.now(),
      ),
    );
  }
}
