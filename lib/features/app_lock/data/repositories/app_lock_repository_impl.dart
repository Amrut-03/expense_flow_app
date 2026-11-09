import 'package:hive/hive.dart';
import 'package:local_auth/local_auth.dart';

import '../../../../core/logging/app_log_buffer.dart';
import '../../domain/repositories/app_lock_repository.dart';

/// App lock backed by `local_auth` (biometrics with device-credential
/// fallback). The on/off flag lives in the encrypted settings box.
class AppLockRepositoryImpl implements AppLockRepository {
  AppLockRepositoryImpl({required this.auth, required this.settingsBox});

  static const _enabledKey = 'app_lock_enabled';

  final LocalAuthentication auth;
  final Box<dynamic> settingsBox;

  @override
  bool isEnabled() => settingsBox.get(_enabledKey) == true;

  @override
  Future<void> setEnabled(bool enabled) =>
      settingsBox.put(_enabledKey, enabled);

  @override
  Future<bool> isSupported() async {
    try {
      return await auth.isDeviceSupported();
    } catch (e, st) {
      AppLogBuffer.instance.captureError('appLock.isSupported', e, st);
      return false;
    }
  }

  @override
  Future<AppLockAuthResult> authenticate({required String reason}) async {
    try {
      final ok = await auth.authenticate(
        localizedReason: reason,
        // Allow the device PIN/pattern as a fallback to biometrics.
        biometricOnly: false,
        persistAcrossBackgrounding: true,
      );
      return ok ? AppLockAuthResult.success : AppLockAuthResult.failed;
    } on LocalAuthException catch (e) {
      return switch (e.code) {
        LocalAuthExceptionCode.noCredentialsSet ||
        LocalAuthExceptionCode.noBiometricHardware ||
        LocalAuthExceptionCode.noBiometricsEnrolled =>
          AppLockAuthResult.unavailable,
        LocalAuthExceptionCode.temporaryLockout ||
        LocalAuthExceptionCode.biometricLockout => AppLockAuthResult.lockedOut,
        _ => AppLockAuthResult.failed,
      };
    } catch (e, st) {
      AppLogBuffer.instance.captureError('appLock.authenticate', e, st);
      return AppLockAuthResult.failed;
    }
  }
}
