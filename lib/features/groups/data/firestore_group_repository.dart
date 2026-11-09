import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/entities/group.dart';
import '../domain/repositories/group_repository.dart';

/// Firestore layout (see firestore.rules):
///
/// * `groups/{id}`: name, kind, ownerUid, memberUids[], members{uid: {name}},
///   monthlyBudget, inviteCode, lastJoinCode, createdAt, updatedAt
/// * `groups/{id}/expenses/{id}`, `groups/{id}/settlements/{id}`
/// * `groupInvites/{code}`: groupId, createdBy, expiresAt. Knowing the code
///   is the capability to join; codes can't be listed.
class FirestoreGroupRepository implements GroupRepository {
  FirestoreGroupRepository({
    required this.firestore,
    required this.getUid,
    required String Function() displayName,
    Random? random,
  }) : _name = displayName,
       _random = random ?? Random.secure();

  final FirebaseFirestore firestore;
  final String? Function() getUid;
  final String Function() _name;
  final Random _random;

  static const maxMembers = 20;
  static const inviteValidity = Duration(days: 7);

  /// No 0/O/1/I/L: codes get read out loud and typed.
  static const _alphabet = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';

  CollectionReference<Map<String, dynamic>> get _groups =>
      firestore.collection('groups');
  CollectionReference<Map<String, dynamic>> get _invites =>
      firestore.collection('groupInvites');

  @override
  String? get currentUid => getUid();

  String _requireUid() {
    final uid = getUid();
    if (uid == null || uid.isEmpty) {
      throw const GroupException(GroupFailure.notSignedIn);
    }
    return uid;
  }

  @override
  Stream<List<SpendingGroup>> watchMyGroups() {
    final uid = getUid();
    if (uid == null) return Stream.value(const []);
    return _groups
        .where('memberUids', arrayContains: uid)
        .snapshots()
        .map(
          (s) =>
              s.docs.map((d) => _group(d.id, d.data())).toList()
                ..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
        );
  }

  @override
  Stream<SpendingGroup?> watchGroup(String groupId) => _groups
      .doc(groupId)
      .snapshots()
      .map((d) => d.exists ? _group(d.id, d.data()!) : null);

  @override
  Stream<List<GroupExpense>> watchExpenses(String groupId) => _groups
      .doc(groupId)
      .collection('expenses')
      .orderBy('date', descending: true)
      .snapshots()
      .map((s) => [for (final d in s.docs) ?_expense(d.id, d.data())]);

  @override
  Stream<List<GroupSettlement>> watchSettlements(String groupId) => _groups
      .doc(groupId)
      .collection('settlements')
      .orderBy('date', descending: true)
      .snapshots()
      .map((s) => [for (final d in s.docs) ?_settlement(d.id, d.data())]);

  @override
  Future<SpendingGroup> create({
    required String name,
    required GroupKind kind,
    double? monthlyBudget,
  }) async {
    final uid = _requireUid();
    final doc = _groups.doc();
    final now = DateTime.now();
    final data = {
      'name': name.trim(),
      'kind': kind.name,
      'ownerUid': uid,
      'memberUids': [uid],
      'members': {
        uid: {'name': _name()},
      },
      'monthlyBudget': monthlyBudget,
      'inviteCode': null,
      'createdAt': Timestamp.fromDate(now),
      'updatedAt': FieldValue.serverTimestamp(),
    };
    await doc.set(data);
    return _group(doc.id, {...data, 'createdAt': Timestamp.fromDate(now)});
  }

  @override
  Future<void> updateBudget(String groupId, double? monthlyBudget) =>
      _groups.doc(groupId).update({
        'monthlyBudget': monthlyBudget,
        'updatedAt': FieldValue.serverTimestamp(),
      });

  String _newCode() => List.generate(
    6,
    (_) => _alphabet[_random.nextInt(_alphabet.length)],
  ).join();

  @override
  Future<String> createInvite(String groupId) async {
    final uid = _requireUid();
    final group = await _groups.doc(groupId).get();
    final old = group.data()?['inviteCode'] as String?;
    final code = _newCode();
    final batch = firestore.batch()
      ..set(_invites.doc(code), {
        'groupId': groupId,
        'createdBy': uid,
        'expiresAt': Timestamp.fromDate(DateTime.now().add(inviteValidity)),
      })
      ..update(_groups.doc(groupId), {
        'inviteCode': code,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    if (old != null) batch.delete(_invites.doc(old));
    await batch.commit();
    return code;
  }

  @override
  Future<SpendingGroup> join(String code) async {
    final uid = _requireUid();
    final normalized = code.trim().toUpperCase();
    final invite = await _invites.doc(normalized).get();
    final data = invite.data();
    if (!invite.exists || data == null) {
      throw const GroupException(GroupFailure.inviteNotFound);
    }
    final expires = (data['expiresAt'] as Timestamp?)?.toDate();
    if (expires == null || expires.isBefore(DateTime.now())) {
      throw const GroupException(GroupFailure.inviteExpired);
    }
    final groupId = data['groupId'] as String;
    try {
      await _groups.doc(groupId).update({
        'memberUids': FieldValue.arrayUnion([uid]),
        'members.$uid': {'name': _name()},
        'lastJoinCode': normalized,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      // Rules reject joins beyond maxMembers.
      if (e.code == 'permission-denied') {
        throw const GroupException(GroupFailure.groupFull);
      }
      rethrow;
    }
    final joined = await _groups.doc(groupId).get();
    return _group(joined.id, joined.data()!);
  }

  @override
  Future<void> leave(String groupId) async {
    final uid = _requireUid();
    final doc = await _groups.doc(groupId).get();
    final members = List<String>.from(doc.data()?['memberUids'] ?? const []);
    if (members.length <= 1) {
      await _groups.doc(groupId).delete();
      return;
    }
    await _groups.doc(groupId).update({
      'memberUids': FieldValue.arrayRemove([uid]),
      'members.$uid': FieldValue.delete(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> addExpense(String groupId, GroupExpense e) =>
      _groups.doc(groupId).collection('expenses').doc(e.id).set({
        'title': e.title,
        'amount': e.amount,
        'paidBy': e.paidBy,
        'shares': e.shares,
        'categoryId': e.categoryId,
        'date': Timestamp.fromDate(e.date),
        'createdBy': e.createdBy,
        'createdAt': Timestamp.fromDate(e.createdAt),
      });

  @override
  Future<void> deleteExpense(String groupId, String expenseId) =>
      _groups.doc(groupId).collection('expenses').doc(expenseId).delete();

  @override
  Future<void> addSettlement(String groupId, GroupSettlement s) =>
      _groups.doc(groupId).collection('settlements').doc(s.id).set({
        'from': s.from,
        'to': s.to,
        'amount': s.amount,
        'date': Timestamp.fromDate(s.date),
        'createdBy': s.createdBy,
      });

  static DateTime _date(Object? v) =>
      v is Timestamp ? v.toDate() : DateTime.fromMillisecondsSinceEpoch(0);

  static SpendingGroup _group(String id, Map<String, dynamic> d) {
    final members = d['members'] is Map ? d['members'] as Map : const {};
    final uids = List<String>.from(d['memberUids'] ?? const []);
    return SpendingGroup(
      id: id,
      name: d['name'] as String? ?? '',
      kind: GroupKind.fromName(d['kind']),
      ownerUid: d['ownerUid'] as String? ?? '',
      members: [
        for (final uid in uids)
          GroupMember(
            uid: uid,
            name:
                (members[uid] is Map ? members[uid]['name'] : null)
                    as String? ??
                '—',
          ),
      ],
      monthlyBudget: (d['monthlyBudget'] as num?)?.toDouble(),
      inviteCode: d['inviteCode'] as String?,
      createdAt: _date(d['createdAt']),
    );
  }

  static GroupExpense? _expense(String id, Map<String, dynamic> d) {
    final amount = (d['amount'] as num?)?.toDouble();
    final paidBy = d['paidBy'] as String?;
    final shares = d['shares'];
    if (amount == null || paidBy == null || shares is! Map) return null;
    return GroupExpense(
      id: id,
      title: d['title'] as String? ?? '',
      amount: amount,
      paidBy: paidBy,
      shares: {
        for (final e in shares.entries)
          if (e.key is String && e.value is num)
            e.key as String: (e.value as num).toDouble(),
      },
      categoryId: d['categoryId'] as String?,
      date: _date(d['date']),
      createdBy: d['createdBy'] as String? ?? '',
      createdAt: _date(d['createdAt']),
    );
  }

  static GroupSettlement? _settlement(String id, Map<String, dynamic> d) {
    final amount = (d['amount'] as num?)?.toDouble();
    final from = d['from'] as String?;
    final to = d['to'] as String?;
    if (amount == null || from == null || to == null) return null;
    return GroupSettlement(
      id: id,
      from: from,
      to: to,
      amount: amount,
      date: _date(d['date']),
      createdBy: d['createdBy'] as String? ?? '',
    );
  }
}
