import 'package:dartz/dartz.dart';
import '../../../../core/error/error_formatter.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/logging/app_log_buffer.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/budget_entity.dart';
import '../../domain/repositories/budget_sync_repository.dart';
import '../datasources/local/budget_local_datasource_impl.dart';
import '../datasources/remote/budget_remote_datasource.dart';
import '../models/budget_model.dart';

class BudgetSyncRepositoryImpl implements BudgetSyncRepository {
  final BudgetLocalDataSource localDataSource;
  final BudgetRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  BudgetSyncRepositoryImpl({
    required this.localDataSource,
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, void>> pushPendingChanges() async {
    try {
      if (!await networkInfo.isConnected) {
        return const Left(NetworkFailure('No internet connection'));
      }
      final all = await localDataSource.getAll();
      final pending = all.where((m) => m.syncStatus != 'synced').toList();
      final updated = [...all];

      for (final model in pending) {
        if (model.isDeleted) {
          await remoteDataSource.deleteBudget(model.categoryId);
          updated.removeWhere((m) => m.categoryId == model.categoryId);
        } else {
          await remoteDataSource.pushBudget(model);
          final index = updated.indexWhere(
            (m) => m.categoryId == model.categoryId,
          );
          updated[index] = model.copyWith(
            syncStatus: 'synced',
            lastSyncedAt: DateTime.now(),
          );
        }
      }

      await localDataSource.saveAll(updated);
      return const Right(null);
    } catch (e) {
      AppLogBuffer.instance.captureError(
        'budgetSync.push',
        e,
        StackTrace.current,
      );
      return Left(SyncFailure(friendlyError(e)));
    }
  }

  @override
  Future<Either<Failure, void>> pullRemoteChanges() async {
    try {
      if (!await networkInfo.isConnected) {
        return const Left(NetworkFailure('No internet connection'));
      }
      final remote = await remoteDataSource.fetchBudgets();
      await _mergeIntoLocal(remote);
      return const Right(null);
    } catch (e) {
      AppLogBuffer.instance.captureError(
        'budgetSync.pull',
        e,
        StackTrace.current,
      );
      return Left(SyncFailure(friendlyError(e)));
    }
  }

  @override
  Stream<List<BudgetEntity>> watchRemoteBudgets() {
    return remoteDataSource.watchBudgets().asyncMap((remote) async {
      await _mergeIntoLocal(remote);
      final local = await localDataSource.getAll();
      return local.map((m) => m.toEntity()).toList();
    });
  }

  Future<void> _mergeIntoLocal(List<BudgetModel> remote) async {
    final local = await localDataSource.getAll();
    final merged = <String, BudgetModel>{
      for (final m in local) m.categoryId: m,
    };

    for (final r in remote) {
      final current = merged[r.categoryId];
      if (current == null) {
        merged[r.categoryId] = r.copyWith(syncStatus: 'synced');
      } else if (current.syncStatus == 'synced' &&
          r.updatedAtOrNow.isAfter(current.updatedAtOrNow)) {
        merged[r.categoryId] = r.copyWith(syncStatus: 'synced');
      }
    }

    await localDataSource.saveAll(merged.values.toList());
  }
}
