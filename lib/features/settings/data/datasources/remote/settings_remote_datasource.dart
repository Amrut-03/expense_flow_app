import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../domain/entities/user_settings.dart';

abstract class SettingsRemoteDataSource {
  Future<void> push(UserSettings settings);
  Future<UserSettings?> fetch();
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
    }, SetOptions(merge: true));
  }

  @override
  Future<UserSettings?> fetch() async {
    final uid = getUid();
    if (uid == null || uid.isEmpty) {
      return null;
    }
    final doc = await _settings.doc(uid).get();
    if (!doc.exists) {
      return null;
    }
    final data = doc.data();
    if (data == null) {
      return null;
    }
    return UserSettings(
      darkMode: data['darkMode'] as bool? ?? false,
      currencyCode: data['currencyCode'] as String? ?? 'INR',
    );
  }
}
