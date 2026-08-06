/// Contract for persisting/removing the device FCM token.
abstract class FcmTokenRepository {
  Future<void> saveToken(String token);
  Future<void> deleteToken(String token);
}
