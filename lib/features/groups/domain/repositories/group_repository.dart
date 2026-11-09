import '../entities/group.dart';

enum GroupFailure {
  notSignedIn,
  inviteNotFound,
  inviteExpired,
  groupFull,
  network,
}

class GroupException implements Exception {
  const GroupException(this.failure);
  final GroupFailure failure;

  @override
  String toString() => 'GroupException($failure)';
}

/// Shared groups live in Firestore (they're inherently multi-user).
abstract interface class GroupRepository {
  String? get currentUid;

  Stream<List<SpendingGroup>> watchMyGroups();
  Stream<SpendingGroup?> watchGroup(String groupId);
  Stream<List<GroupExpense>> watchExpenses(String groupId);
  Stream<List<GroupSettlement>> watchSettlements(String groupId);

  Future<SpendingGroup> create({
    required String name,
    required GroupKind kind,
    double? monthlyBudget,
  });
  Future<void> updateBudget(String groupId, double? monthlyBudget);

  /// Creates (or rotates) a 7-day invite code.
  Future<String> createInvite(String groupId);
  Future<SpendingGroup> join(String code);
  Future<void> leave(String groupId);

  Future<void> addExpense(String groupId, GroupExpense expense);
  Future<void> deleteExpense(String groupId, String expenseId);
  Future<void> addSettlement(String groupId, GroupSettlement settlement);
}
