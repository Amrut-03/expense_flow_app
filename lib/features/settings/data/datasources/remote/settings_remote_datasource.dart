import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../domain/entities/user_settings.dart';

abstract class SettingsRemoteDataSource {
  Future<void> push(UserSettings settings);
  Future<Map<String, dynamic>?> fetch();
}

class SettingsRemoteDataSourceImpl implements SettingsRemoteDataSource {
  final FirebaseFirestore firestore;
  final String? Function() getUid;

  SettingsRemoteDataSourceImpl({required this.firestore, required this.getUid});

  static const _collection = 'settings';

  CollectionReference<Map<String, dynamic>> get _settings =>
      firestore.collection(_collection);

  @override
  Future<void> push(UserSettings settings) async {
    final uid = getUid();
    if (uid == null || uid.isEmpty) {
      throw Exception('No signed-in user to sync settings');
    }
    await _settings.doc(uid).set({
      'darkMode': settings.darkMode,
      'currencyCode': settings.currencyCode,
      'localeCode': settings.localeCode,
    }, SetOptions(merge: true));
  }

  /// Returns the raw stored settings document so the repository can merge the
  /// remote values over the local ones. A `null` return means either the user
  /// is not signed in, there is no stored document, or the document is empty.
  @override
  Future<Map<String, dynamic>?> fetch() async {
    final uid = getUid();
    if (uid == null || uid.isEmpty) {
      return null;
    }
    final doc = await _settings.doc(uid).get();
    final data = doc.data();
    if (!doc.exists || data == null) {
      return null;
    }
    return data;
  }
}
