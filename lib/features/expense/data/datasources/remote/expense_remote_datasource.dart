import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expense_flow_app/features/expense/data/models/expense_model.dart';
import '../../../domain/entities/expense_entity.dart';

abstract class ExpenseRemoteDataSource {
  Future<void> pushExpense(ExpenseModel expense);
  Future<List<ExpenseModel>> fetchExpenses();
  Future<void> deleteExpense(String id);
  Stream<List<ExpenseModel>> watchExpenses();
}

class ExpenseRemoteDataSourceImpl implements ExpenseRemoteDataSource {
  final FirebaseFirestore firestore;
  final String? Function() getUid;

  ExpenseRemoteDataSourceImpl({required this.firestore, required this.getUid});

  static const String _collection = 'transactions';

  CollectionReference<Map<String, dynamic>> get _transactions =>
      firestore.collection(_collection);

  String _requireUid() {
    final uid = getUid();

    if (uid == null || uid.isEmpty) {
      throw Exception('No signed-in user to access remote data');
    }

    return uid;
  }

  @override
  Future<void> pushExpense(ExpenseModel expense) async {
    final uid = _requireUid();

    final data = expense.toJson()
      ..['uid'] = uid
      ..['serverId'] = expense.id
      ..['syncStatus'] = SyncStatus.synced.name
      ..['lastSyncedAt'] = DateTime.now().toIso8601String();

    await _transactions.doc(expense.id).set(data, SetOptions(merge: true));
  }

  @override
  Future<List<ExpenseModel>> fetchExpenses() async {
    final uid = _requireUid();

    final snapshot = await _transactions.where('uid', isEqualTo: uid).get();

    return snapshot.docs.map((doc) {
      final data = Map<String, dynamic>.from(doc.data());

      data['serverId'] = doc.id;

      return ExpenseModel.fromJson(data);
    }).toList();
  }

  @override
  Future<void> deleteExpense(String id) async {
    await _transactions.doc(id).delete();
  }

  @override
  Stream<List<ExpenseModel>> watchExpenses() {
    final uid = getUid();

    if (uid == null || uid.isEmpty) {
      return const Stream.empty();
    }

    return _transactions
        .where('uid', isEqualTo: uid)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map((doc) {
            final data = Map<String, dynamic>.from(doc.data());

            data['serverId'] = doc.id;

            return ExpenseModel.fromJson(data);
          }).toList(),
        );
  }
}
