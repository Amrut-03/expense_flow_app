import 'package:dartz/dartz.dart';
import 'package:expense_flow_app/core/error/error_formatter.dart';
import 'package:expense_flow_app/core/error/failures.dart';
import 'package:expense_flow_app/core/network/network_info.dart';
import 'package:expense_flow_app/features/expense/data/datasources/remote/expense_remote_datasource.dart';
import 'package:expense_flow_app/features/expense/domain/entities/expense_entity.dart';

import '../../../expense/data/datasources/local/expense_local_datasource_impl.dart';
import '../../domain/repositories/sync_repository.dart';

class SyncRepositoryImpl implements SyncRepository {
  final ExpenseLocalDataSource localDataSource;
  final ExpenseRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  SyncRepositoryImpl({
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

      final models = await localDataSource.getExpenses();
      final pending = models
          .where((m) => m.syncStatus != SyncStatus.synced.name)
          .toList();

      for (final model in pending) {
        if (model.isDeleted) {
          await remoteDataSource.deleteExpense(model.id);
          await localDataSource.deleteExpense(model.id);
        } else {
          await remoteDataSource.pushExpense(model);
          await localDataSource.updateExpense(
            model.copyWith(
              syncStatus: SyncStatus.synced.name,
              lastSyncedAt: DateTime.now(),
            ),
          );
        }
      }

      return const Right(null);
    } catch (e) {
      return Left(SyncFailure(friendlyError(e)));
    }
  }

  @override
  Future<Either<Failure, void>> pullRemoteChanges() async {
    try {
      if (!await networkInfo.isConnected) {
        return const Left(NetworkFailure('No internet connection'));
      }

      final remoteModels = await remoteDataSource.fetchExpenses();
      final localModels = await localDataSource.getExpenses();
      final localById = {for (final m in localModels) m.id: m};

      for (final remote in remoteModels) {
        final local = localById[remote.id];

        if (local == null) {
          if (!remote.isDeleted) {
            await localDataSource.addExpense(
              remote.copyWith(
                syncStatus: SyncStatus.synced.name,
                serverId: remote.serverId ?? remote.id,
                lastSyncedAt: DateTime.now(),
              ),
            );
          }
        } else if (remote.isDeleted) {
          await localDataSource.deleteExpense(remote.id);
        } else if (local.syncStatus == SyncStatus.synced.name &&
            remote.updatedAt.isAfter(local.updatedAt)) {
          await localDataSource.updateExpense(
            remote.copyWith(
              syncStatus: SyncStatus.synced.name,
              serverId: remote.serverId ?? remote.id,
              lastSyncedAt: DateTime.now(),
            ),
          );
        }
      }

      return const Right(null);
    } catch (e) {
      return Left(SyncFailure(friendlyError(e)));
    }
  }

  @override
  Stream<List<ExpenseEntity>> watchRemoteExpenses() {
    return remoteDataSource.watchExpenses().map(
      (models) => models.map((model) => model.toEntity()).toList(),
    );
  }
}
