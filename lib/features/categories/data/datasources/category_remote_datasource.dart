import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/custom_category.dart';

abstract class CategoryRemoteDataSource {
  Future<List<CustomCategory>?> fetch();
  Future<void> push(List<CustomCategory> categories);
}

/// Stores custom categories as a `customCategories` array on the user's
/// existing `settings/{uid}` document, which the security rules already
/// scope to the owner.
class CategoryRemoteDataSourceImpl implements CategoryRemoteDataSource {
  CategoryRemoteDataSourceImpl({required this.firestore, required this.getUid});

  final FirebaseFirestore firestore;
  final String? Function() getUid;

  static const _field = 'customCategories';

  DocumentReference<Map<String, dynamic>>? _doc() {
    final uid = getUid();
    if (uid == null || uid.isEmpty) return null;
    return firestore.collection('settings').doc(uid);
  }

  @override
  Future<List<CustomCategory>?> fetch() async {
    final doc = _doc();
    if (doc == null) return null;
    final raw = (await doc.get()).data()?[_field];
    if (raw is! List) return null;
    return raw.map(CustomCategory.fromMap).whereType<CustomCategory>().toList();
  }

  @override
  Future<void> push(List<CustomCategory> categories) async {
    final doc = _doc();
    if (doc == null) return;
    await doc.set({
      _field: [for (final c in categories) c.toMap()],
    }, SetOptions(merge: true));
  }
}
