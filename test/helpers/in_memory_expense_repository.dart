import 'package:expense_flow_app/features/expense/domain/entities/expense_entity.dart';
import 'package:expense_flow_app/features/expense/domain/repositories/expense_repository.dart';

/// Map-backed [ExpenseRepository]: same put-by-id semantics as the Hive
/// datasource, so idempotency can be asserted.
class InMemoryExpenseRepository implements ExpenseRepository {
  final Map<String, ExpenseEntity> byId = {};

  @override
  Future<void> addExpense(ExpenseEntity expense) async {
    byId[expense.id] = expense;
  }

  @override
  Future<void> updateExpense(ExpenseEntity expense) async {
    byId[expense.id] = expense;
  }

  @override
  Future<void> deleteExpense(String id) async {
    byId.remove(id);
  }

  @override
  Future<ExpenseEntity?> getExpenseById(String id) async => byId[id];

  @override
  Future<List<ExpenseEntity>> getExpenses() async {
    return byId.values.toList()..sort((a, b) => b.date.compareTo(a.date));
  }
}
