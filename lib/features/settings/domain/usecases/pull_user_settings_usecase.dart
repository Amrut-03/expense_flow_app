import '../entities/user_settings.dart';
import '../repositories/user_settings_repository.dart';

class PullUserSettingsUseCase {
  final UserSettingsRepository repository;

  const PullUserSettingsUseCase(this.repository);

  Future<UserSettings?> call() => repository.pullRemote();
}
