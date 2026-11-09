import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive/hive.dart';

/// Persists the 256-bit Hive AES key in the platform keystore
/// (Android Keystore / iOS Keychain) via `flutter_secure_storage`.
class HiveEncryptionKeyStore {
  HiveEncryptionKeyStore([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

  static const _keyName = 'expenseflow_hive_aes_key_v1';

  final FlutterSecureStorage _storage;

  /// Returns the stored key, or `null` if none exists (first launch, or the
  /// keystore was reset).
  Future<List<int>?> read() async {
    final encoded = await _storage.read(key: _keyName);
    if (encoded == null || encoded.isEmpty) return null;

    final bytes = base64Url.decode(encoded);
    return bytes.length == 32 ? bytes : null;
  }

  /// Generates, persists and returns a fresh key.
  Future<List<int>> create() async {
    final key = Hive.generateSecureKey();
    await _storage.write(key: _keyName, value: base64Url.encode(key));
    return key;
  }
}
