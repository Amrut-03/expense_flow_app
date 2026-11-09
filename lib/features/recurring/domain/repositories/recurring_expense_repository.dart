import '../entities/recurring_expense_entity.dart';

abstract class RecurringExpenseRepository {
  Future<List<RecurringExpenseEntity>> getAll();

  Future<RecurringExpenseEntity?> getById(String id);

  /// Inserts or replaces the rule with the same id.
  Future<void> save(RecurringExpenseEntity rule);

  Future<void> delete(String id);

  /// Emits whenever any rule changes.
  Stream<void> watch();
}
