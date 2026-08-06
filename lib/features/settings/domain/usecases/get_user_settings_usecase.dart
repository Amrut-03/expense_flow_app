import '../entities/user_settings.dart';
import '../repositories/user_settings_repository.dart';

class GetUserSettingsUseCase {
  final UserSettingsRepository repository;

  const GetUserSettingsUseCase(this.repository);

  Future<UserSettings> call() => repository.readLocal();
}
