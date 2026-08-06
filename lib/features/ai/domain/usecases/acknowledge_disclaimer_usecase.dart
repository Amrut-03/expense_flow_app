import '../repositories/ai_disclaimer_repository.dart';

/// Records that the user has seen and accepted the AI disclaimer.
class AcknowledgeDisclaimerUseCase {
  AcknowledgeDisclaimerUseCase({required this.repository});

  final AiDisclaimerRepository repository;

  Future<void> call() => repository.markDisclaimerSeen();
}
