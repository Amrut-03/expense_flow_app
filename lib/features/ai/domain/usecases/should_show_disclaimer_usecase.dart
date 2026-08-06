import '../repositories/ai_disclaimer_repository.dart';

/// Returns whether the one-time AI disclaimer still has to be shown.
class ShouldShowDisclaimerUseCase {
  ShouldShowDisclaimerUseCase({required this.repository});

  final AiDisclaimerRepository repository;

  /// Returns `false` once the disclaimer has been acknowledged.
  Future<bool> call() async => !(await repository.hasSeenDisclaimer());
}
