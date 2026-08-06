/// Persists the one-time AI safety disclaimer acknowledgement.
abstract interface class AiDisclaimerRepository {
  /// Returns whether the disclaimer has already been acknowledged.
  Future<bool> hasSeenDisclaimer();

  /// Records that the user has seen and accepted the disclaimer.
  Future<void> markDisclaimerSeen();
}
