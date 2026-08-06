import 'package:hive/hive.dart';
import '../../models/expense_model.dart';

abstract class ExpenseLocalDataSource {
  Future<void> addExpense(ExpenseModel expense);
  Future<List<ExpenseModel>> getExpenses();
  Future<void> updateExpense(ExpenseModel expense);
  Future<void> deleteExpense(String id);
  Future<ExpenseModel?> getExpenseById(String id);
  Future<void> clear();
}

class ExpenseLocalDataSourceImpl implements ExpenseLocalDataSource {
  final Box<ExpenseModel> expenseBox;

  ExpenseLocalDataSourceImpl(this.expenseBox);

  @override
  Future<void> addExpense(ExpenseModel expense) async {
    await expenseBox.put(expense.id, expense);
  }

  @override
  Future<void> updateExpense(ExpenseModel expense) async {
    await expenseBox.put(expense.id, expense);
  }

  @override
  Future<void> deleteExpense(String id) async {
    await expenseBox.delete(id);
  }

  @override
  Future<List<ExpenseModel>> getExpenses() async {
    final expenses = expenseBox.values.toList();

    expenses.sort((a, b) => b.date.compareTo(a.date));

    return expenses;
  }

  @override
  Future<ExpenseModel?> getExpenseById(String id) async {
    return expenseBox.get(id);
  }

  @override
  Future<void> clear() async {
    await expenseBox.clear();
  }
}
