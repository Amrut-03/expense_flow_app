import 'package:hive/hive.dart';

import '../../domain/entities/budget_rollover.dart';
import '../../domain/repositories/budget_rollover_repository.dart';

class BudgetRolloverRepositoryImpl implements BudgetRolloverRepository {
  BudgetRolloverRepositoryImpl(this.box);

  final Box<dynamic> box;

  static const _settingsKey = 'budget_rollover';

  @override
  Map<String, BudgetRolloverSetting> getAll() {
    final raw = box.get(_settingsKey);
    if (raw is! Map) return {};
    return {
      for (final entry in raw.entries)
        if (entry.key is String)
          entry.key as String: BudgetRolloverSetting.fromMap(entry.value),
    };
  }

  @override
  Future<void> set(String categoryId, BudgetRolloverSetting setting) {
    final all = {for (final e in getAll().entries) e.key: e.value.toMap()};
    if (setting.mode == BudgetRolloverMode.none) {
      all.remove(categoryId);
    } else {
      all[categoryId] = setting.toMap();
    }
    return box.put(_settingsKey, all);
  }

  String _settledKey(String categoryId, DateTime start) =>
      'rollover_settled_${categoryId}_${start.year}_${start.month}';

  @override
  bool isSettled(String categoryId, DateTime periodStart) =>
      box.get(_settledKey(categoryId, periodStart)) == true;

  @override
  Future<void> markSettled(String categoryId, DateTime periodStart) =>
      box.put(_settledKey(categoryId, periodStart), true);
}
