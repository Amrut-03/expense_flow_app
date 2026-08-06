import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/user_settings.dart';

abstract class UserSettingsRepository {
  Future<UserSettings> readLocal();
  Future<void> updateLocal(UserSettings settings);
  Future<Either<Failure, void>> push(UserSettings settings);
  Future<UserSettings?> pullRemote();
}
