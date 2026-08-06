import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/foundation.dart';

import '../../domain/repositories/fcm_token_repository.dart';
import '../datasources/fcm_token_datasource.dart';

class FcmTokenRepositoryImpl implements FcmTokenRepository {
  final FcmTokenDataSource dataSource;
  final fb.FirebaseAuth firebaseAuth;

  FcmTokenRepositoryImpl({
    required this.dataSource,
    required this.firebaseAuth,
  });

  String _platform() {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'android';
      case TargetPlatform.iOS:
        return 'ios';
      default:
        return 'other';
    }
  }

  String? get _uid => firebaseAuth.currentUser?.uid;

  @override
  Future<void> saveToken(String token) async {
    final uid = _uid;
    if (uid == null) return;

    await dataSource.saveToken(uid: uid, token: token, platform: _platform());
  }

  @override
  Future<void> deleteToken(String token) async {
    final uid = _uid;
    if (uid == null) return;

    await dataSource.deleteToken(uid: uid, token: token);
  }
}
