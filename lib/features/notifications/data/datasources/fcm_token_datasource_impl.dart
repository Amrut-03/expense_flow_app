import 'package:cloud_firestore/cloud_firestore.dart';

import 'fcm_token_datasource.dart';

class FcmTokenDataSourceImpl implements FcmTokenDataSource {
  final FirebaseFirestore firestore;

  FcmTokenDataSourceImpl(this.firestore);

  static const String _usersCollection = 'users';

  DocumentReference<Map<String, dynamic>> _deviceRef(String uid, String token) {
    // Firestore document IDs cannot contain '/'. Scrubbing keeps the write
    // idempotent per device token across refreshes.
    final safeToken = token.replaceAll('/', '_');
    return firestore
        .collection(_usersCollection)
        .doc(uid)
        .collection('devices')
        .doc(safeToken);
  }

  @override
  Future<void> saveToken({
    required String uid,
    required String token,
    required String platform,
  }) async {
    if (token.isEmpty) return;

    await _deviceRef(uid, token).set({
      'token': token,
      'platform': platform,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> deleteToken({required String uid, required String token}) async {
    if (token.isEmpty) return;

    await _deviceRef(uid, token).delete();
  }
}
