/// Remote persistence for the device's FCM token.
///
/// Tokens are stored per user under `users/{uid}/devices` so server-side
/// Cloud Functions can read them and send targeted push notifications.
abstract class FcmTokenDataSource {
  Future<void> saveToken({
    required String uid,
    required String token,
    required String platform,
  });

  Future<void> deleteToken({required String uid, required String token});
}
