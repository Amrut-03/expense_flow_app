import '../../domain/entities/recurring_expense_entity.dart';
import '../../domain/repositories/recurring_expense_repository.dart';
import '../datasources/recurring_expense_local_datasource.dart';
import '../models/recurring_expense_model.dart';

/// Local-only for now; rules live in the encrypted Hive box on this device.
/// The expenses they generate sync through the regular expense pipeline.
class RecurringExpenseRepositoryImpl implements RecurringExpenseRepository {
  RecurringExpenseRepositoryImpl(this._local);

  final RecurringExpenseLocalDataSource _local;

  @override
  Future<List<RecurringExpenseEntity>> getAll() async {
    return _local.getAll().map((m) => m.toEntity()).toList();
  }

  @override
  Future<RecurringExpenseEntity?> getById(String id) async {
    return _local.getById(id)?.toEntity();
  }

  @override
  Future<void> save(RecurringExpenseEntity rule) {
    return _local.put(RecurringExpenseModel.fromEntity(rule));
  }

  @override
  Future<void> delete(String id) => _local.delete(id);

  @override
  Stream<void> watch() => _local.watch();
}
