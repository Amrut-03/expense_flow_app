import 'package:expense_flow_app/features/budget/data/datasources/local/budget_local_datasource_impl.dart';

import '../../domain/entities/budget_entity.dart';
import '../../domain/repositories/budget_repository.dart';
import '../models/budget_model.dart';

class BudgetRepositoryImpl implements BudgetRepository {
  final BudgetLocalDataSource localDataSource;

  BudgetRepositoryImpl({required this.localDataSource});

  @override
  Future<Map<String, double>> getLimits() async {
    final models = await localDataSource.getAll();
    return {for (final m in models) m.categoryId: m.limit};
  }

  @override
  Future<Map<String, BudgetPeriod>> getPeriods() async {
    final models = await localDataSource.getAll();
    return {for (final m in models) m.categoryId: m.period};
  }

  @override
  Future<void> setLimits(Map<String, double> limits) async {
    final existing = await localDataSource.getAll();
    final existingById = {for (final m in existing) m.categoryId: m};
    final periodMap = {for (final m in existing) m.categoryId: m.period};

    final models = limits.entries
        .map(
          (e) => _withSyncState(
            existing: existingById[e.key],
            categoryId: e.key,
            limit: e.value,
            period: periodMap[e.key] ?? BudgetPeriod.monthly,
          ),
        )
        .toList();
    await localDataSource.saveAll(models);
  }

  @override
  Future<void> setPeriods(Map<String, BudgetPeriod> periods) async {
    final existing = await localDataSource.getAll();
    final existingById = {for (final m in existing) m.categoryId: m};
    final limitMap = {for (final m in existing) m.categoryId: m.limit};

    final models = periods.entries
        .map(
          (e) => _withSyncState(
            existing: existingById[e.key],
            categoryId: e.key,
            limit: limitMap[e.key] ?? 0,
            period: e.value,
          ),
        )
        .toList();
    await localDataSource.saveAll(models);
  }

  @override
  Future<void> setAll(
    Map<String, double> limits,
    Map<String, BudgetPeriod> periods,
  ) async {
    final existing = await localDataSource.getAll();
    final existingById = {for (final m in existing) m.categoryId: m};
    final allCategoryIds = {...limits.keys, ...periods.keys};

    final models = allCategoryIds.map(
      (id) => _withSyncState(
        existing: existingById[id],
        categoryId: id,
        limit: limits[id] ?? 0,
        period: periods[id] ?? BudgetPeriod.monthly,
      ),
    );

    await localDataSource.saveAll(models.toList());
  }

  /// Preserves sync metadata so unchanged budgets stay `synced` and are not
  /// re-pushed to Firestore. Only changed budgets become `pending` again.
  BudgetModel _withSyncState({
    required BudgetModel? existing,
    required String categoryId,
    required double limit,
    required BudgetPeriod period,
  }) {
    if (existing != null &&
        existing.limit == limit &&
        existing.period == period) {
      return existing;
    }

    return BudgetModel(
      categoryId: categoryId,
      limit: limit,
      period: period,
      createdAt: existing?.createdAt,
      updatedAt: DateTime.now(),
      lastSyncedAt: existing?.lastSyncedAt,
      syncStatus: 'pending',
      isDeleted: existing?.isDeleted ?? false,
    );
  }
}
