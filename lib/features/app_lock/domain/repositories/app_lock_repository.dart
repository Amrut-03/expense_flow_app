enum AppLockAuthResult {
  success,

  /// User cancelled or the biometric/PIN did not match.
  failed,

  /// No biometrics or device credential is set up on this device.
  unavailable,

  /// Too many failed attempts; the OS has temporarily locked authentication.
  lockedOut,
}

abstract class AppLockRepository {
  bool isEnabled();

  Future<void> setEnabled(bool enabled);

  /// Whether the device can authenticate the user at all (biometrics or a
  /// device PIN/pattern/passcode).
  Future<bool> isSupported();

  Future<AppLockAuthResult> authenticate({required String reason});
}
