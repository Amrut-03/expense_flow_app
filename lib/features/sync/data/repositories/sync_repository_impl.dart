import 'package:dartz/dartz.dart';
import 'package:expense_flow_app/core/error/failures.dart';
import 'package:expense_flow_app/core/network/network_info.dart';
import 'package:expense_flow_app/features/expense/data/datasources/remote/expense_remote_datasource.dart';
import 'package:expense_flow_app/features/expense/data/models/expense_model.dart';
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
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure('No internet connection'));
    }

    final models = await localDataSource.getExpenses();
    final pending = models
        .where((m) => m.syncStatus != SyncStatus.synced.name)
        .toList();

    var failures = 0;

    for (final model in pending) {
      try {
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
      } catch (_) {
        // A single item must never abort the whole sync. Record the failure
        // on the item (`failed` keeps it in the next run's pending set) so it
        // is retried automatically on the next push instead of being lost.
        failures++;
        await localDataSource.updateExpense(
          model.copyWith(syncStatus: SyncStatus.failed.name),
        );
      }
    }

    if (failures > 0) {
      return Left(
        SyncFailure(
          '$failures change(s) could not be synced and will be retried '
          'automatically.',
        ),
      );
    }
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> pullRemoteChanges() async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure('No internet connection'));
    }

    final remoteModels = await remoteDataSource.fetchExpenses();
    final localModels = await localDataSource.getExpenses();
    final localById = {for (final m in localModels) m.id: m};

    var conflicts = 0;

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
        continue;
      }

      if (remote.isDeleted) {
        if (local.syncStatus == SyncStatus.synced.name) {
          await localDataSource.deleteExpense(remote.id);
        } else {
          // The local copy holds unsynced edits while the remote says it was
          // deleted. Protect the local change and surface the conflict; the
          // next push resolves it (last-writer-wins).
          conflicts++;
          await localDataSource.updateExpense(
            local.copyWith(syncStatus: SyncStatus.conflict.name),
          );
        }
        continue;
      }

      final remoteIsNewer = remote.updatedAt.isAfter(local.updatedAt);

      if (local.syncStatus == SyncStatus.synced.name && remoteIsNewer) {
        await localDataSource.updateExpense(
          remote.copyWith(
            syncStatus: SyncStatus.synced.name,
            serverId: remote.serverId ?? remote.id,
            lastSyncedAt: DateTime.now(),
          ),
        );
      } else if (local.syncStatus != SyncStatus.synced.name && remoteIsNewer) {
        // Both sides changed since the last sync. Keep the local edits and
        // mark the item `conflict` instead of silently discarding either
        // side. The next push resolves it (last-writer-wins).
        conflicts++;
        await localDataSource.updateExpense(
          local.copyWith(syncStatus: SyncStatus.conflict.name),
        );
      }
    }

    if (conflicts > 0) {
      return Left(
        SyncFailure(
          '$conflicts change(s) conflict with the remote copy and were '
          'kept locally.',
        ),
      );
    }
    return const Right(null);
  }

  @override
  Stream<List<ExpenseEntity>> watchRemoteExpenses() {
    return remoteDataSource.watchExpenses().asyncMap(_mergeWithLocal);
  }

  /// Merges a remote snapshot into the local store and returns the combined,
  /// visible view (local-only pending edits included, soft-deleted entries
  /// excluded).
  ///
  /// This mirrors the pull semantics so a live stream never flashes stale or
  /// deleted rows the user removed locally: clean remote deletions are
  /// applied, remote edits only win when the local copy is synced, and local
  /// unsynced changes are preserved.
  Future<List<ExpenseEntity>> _mergeWithLocal(
    List<ExpenseModel> remoteModels,
  ) async {
    final localModels = await localDataSource.getExpenses();
    final localById = {for (final m in localModels) m.id: m};

    final merged = <String, ExpenseModel>{for (final m in localModels) m.id: m};

    for (final remote in remoteModels) {
      final local = localById[remote.id];

      if (local == null) {
        if (!remote.isDeleted) {
          final model = remote.copyWith(
            syncStatus: SyncStatus.synced.name,
            serverId: remote.serverId ?? remote.id,
          );
          merged[remote.id] = model;
          await localDataSource.addExpense(model);
        }
        continue;
      }

      if (remote.isDeleted) {
        if (local.syncStatus == SyncStatus.synced.name) {
          merged.remove(remote.id);
          await localDataSource.deleteExpense(remote.id);
        }
        continue;
      }

      if (local.syncStatus == SyncStatus.synced.name &&
          remote.updatedAt.isAfter(local.updatedAt)) {
        final model = remote.copyWith(
          syncStatus: SyncStatus.synced.name,
          serverId: remote.serverId ?? remote.id,
          lastSyncedAt: local.lastSyncedAt ?? DateTime.now(),
        );
        merged[remote.id] = model;
        await localDataSource.updateExpense(model);
      }
      // Otherwise keep the local copy: it is either pending (unsynced edits
      // must not be overwritten) or already up to date with the remote.
    }

    final result = merged.values
        .where((m) => !m.isDeleted)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    return result.map((m) => m.toEntity()).toList();
  }
}