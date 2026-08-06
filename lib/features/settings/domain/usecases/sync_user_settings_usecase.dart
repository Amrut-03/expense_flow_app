import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/user_settings.dart';
import '../repositories/user_settings_repository.dart';

class SyncUserSettingsUseCase {
  final UserSettingsRepository repository;

  const SyncUserSettingsUseCase(this.repository);

  Future<Either<Failure, void>> call(UserSettings settings) async {
    await repository.updateLocal(settings);
    return repository.push(settings);
  }
}
