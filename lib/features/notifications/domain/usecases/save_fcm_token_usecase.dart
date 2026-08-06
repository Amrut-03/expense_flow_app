import '../../domain/repositories/fcm_token_repository.dart';

/// Persists the current device's FCM token to the signed-in user's Firestore
/// device registry so the server can target this device.
class SaveFcmTokenUseCase {
  final FcmTokenRepository repository;

  const SaveFcmTokenUseCase(this.repository);

  Future<void> call(String token) {
    return repository.saveToken(token);
  }
}
