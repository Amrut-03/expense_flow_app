import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/budget_model.dart';

abstract class BudgetRemoteDataSource {
  Future<void> pushBudget(BudgetModel budget);
  Future<List<BudgetModel>> fetchBudgets();
  Future<void> deleteBudget(String categoryId);
  Stream<List<BudgetModel>> watchBudgets();
}

class BudgetRemoteDataSourceImpl implements BudgetRemoteDataSource {
  final FirebaseFirestore firestore;
  final String? Function() getUid;

  BudgetRemoteDataSourceImpl({required this.firestore, required this.getUid});

  static const String _collection = 'budgets';

  CollectionReference<Map<String, dynamic>> get _budgets =>
      firestore.collection(_collection);

  String _requireUid() {
    final uid = getUid();
    if (uid == null || uid.isEmpty) {
      throw Exception('No signed-in user to access remote data');
    }
    return uid;
  }

  @override
  Future<void> pushBudget(BudgetModel budget) async {
    final uid = _requireUid();
    final data = budget.toJson()
      ..['uid'] = uid
      ..['syncStatus'] = 'synced'
      ..['lastSyncedAt'] = DateTime.now().toIso8601String();
    await _budgets.doc(budget.categoryId).set(data, SetOptions(merge: true));
  }

  @override
  Future<List<BudgetModel>> fetchBudgets() async {
    final uid = _requireUid();
    final snapshot = await _budgets.where('uid', isEqualTo: uid).get();
    return snapshot.docs
        .map(
          (doc) => BudgetModel.fromJson(Map<String, dynamic>.from(doc.data())),
        )
        .toList();
  }

  @override
  Future<void> deleteBudget(String categoryId) async {
    await _budgets.doc(categoryId).delete();
  }

  @override
  Stream<List<BudgetModel>> watchBudgets() {
    final uid = getUid();
    if (uid == null || uid.isEmpty) {
      return const Stream.empty();
    }
    return _budgets
        .where('uid', isEqualTo: uid)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) =>
                    BudgetModel.fromJson(Map<String, dynamic>.from(doc.data())),
              )
              .toList(),
        );
  }
}
