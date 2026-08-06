import '../entities/expense_entity.dart';
import '../repositories/expense_repository.dart';

class UpdateExpenseUseCase {
  final ExpenseRepository repository;

  const UpdateExpenseUseCase(this.repository);

  Future<void> call(ExpenseEntity expense) async {
    _validate(expense);

    await repository.updateExpense(
      expense.copyWith(
        syncStatus: SyncStatus.pending,
        version: expense.version + 1,
        updatedAt: DateTime.now(),
      ),
    );
  }

  void _validate(ExpenseEntity expense) {
    if (expense.amount <= 0) {
      throw Exception("Amount must be greater than 0");
    }

    final cents = (expense.amount * 100).round();

    if ((expense.amount - cents / 100).abs() > 1e-6) {
      throw Exception("Amount can have maximum 2 decimal places");
    }

    if (expense.amount > 1000000) {
      throw Exception("Amount exceeds allowed limit");
    }

    if (expense.categoryId.trim().isEmpty) {
      throw Exception("Category is required");
    }

    if ((expense.note?.length ?? 0) > 280) {
      throw Exception("Note cannot exceed 280 characters");
    }

    if ((expense.title?.length ?? 0) > 80) {
      throw Exception("Title cannot exceed 80 characters");
    }
  }
}
