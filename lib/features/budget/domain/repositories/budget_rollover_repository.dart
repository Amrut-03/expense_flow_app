import '../entities/budget_rollover.dart';

/// Per-category rollover preferences (local to the device).
abstract class BudgetRolloverRepository {
  Map<String, BudgetRolloverSetting> getAll();
  Future<void> set(String categoryId, BudgetRolloverSetting setting);

  /// Whether the unspent amount of the period starting [periodStart] has
  /// already been moved into a goal.
  bool isSettled(String categoryId, DateTime periodStart);
  Future<void> markSettled(String categoryId, DateTime periodStart);
}
