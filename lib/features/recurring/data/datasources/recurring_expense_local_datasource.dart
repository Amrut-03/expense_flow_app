import 'package:hive/hive.dart';

import '../models/recurring_expense_model.dart';

abstract class RecurringExpenseLocalDataSource {
  List<RecurringExpenseModel> getAll();
  RecurringExpenseModel? getById(String id);
  Future<void> put(RecurringExpenseModel model);
  Future<void> delete(String id);
  Stream<void> watch();
}

class RecurringExpenseLocalDataSourceImpl
    implements RecurringExpenseLocalDataSource {
  RecurringExpenseLocalDataSourceImpl(this._box);

  final Box<RecurringExpenseModel> _box;

  @override
  List<RecurringExpenseModel> getAll() => _box.values.toList();

  @override
  RecurringExpenseModel? getById(String id) => _box.get(id);

  @override
  Future<void> put(RecurringExpenseModel model) => _box.put(model.id, model);

  @override
  Future<void> delete(String id) => _box.delete(id);

  @override
  Stream<void> watch() => _box.watch().map((_) {});
}
