import 'package:dartz/dartz.dart';
import '../../../../core/error/error_formatter.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/user_settings.dart';
import '../../domain/repositories/user_settings_repository.dart';
import '../datasources/local/settings_local_datasource.dart';
import '../datasources/remote/settings_remote_datasource.dart';

class UserSettingsRepositoryImpl implements UserSettingsRepository {
  final SettingsLocalDataSource localDataSource;
  final SettingsRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  UserSettingsRepositoryImpl({
    required this.localDataSource,
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<UserSettings> readLocal() => localDataSource.read();

  @override
  Future<void> updateLocal(UserSettings settings) =>
      localDataSource.write(settings);

  @override
  Future<Either<Failure, void>> push(UserSettings settings) async {
    try {
      if (!await networkInfo.isConnected) {
        return const Left(NetworkFailure('No internet connection'));
      }
      await remoteDataSource.push(settings);
      return const Right(null);
    } catch (e) {
      return Left(SyncFailure(friendlyError(e)));
    }
  }

  @override
  Future<UserSettings?> pullRemote() async {
    try {
      if (!await networkInfo.isConnected) {
        return null;
      }
      final remote = await remoteDataSource.fetch();
      if (remote == null) {
        return null;
      }
      await localDataSource.write(remote);
      return remote;
    } catch (_) {
      return null;
    }
  }
}
