import '../entities/expense_entity.dart';
import '../repositories/expense_repository.dart';
import '../validation/expense_validator.dart';

class UpdateExpenseUseCase {
  final ExpenseRepository repository;
  final DateTime Function() _now;

  UpdateExpenseUseCase(this.repository, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  Future<void> call(ExpenseEntity expense) async {
    ExpenseValidator.validate(
      amount: expense.amount,
      categoryId: expense.categoryId,
      note: expense.note,
      title: expense.title,
      merchant: expense.merchant,
      originalAmount: expense.originalAmount,
      exchangeRate: expense.exchangeRate,
    );

    await repository.updateExpense(
      expense.copyWith(
        syncStatus: SyncStatus.pending,
        version: expense.version + 1,
        updatedAt: _now(),
      ),
    );
  }
}
