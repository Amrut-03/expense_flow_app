import 'package:equatable/equatable.dart';

enum GroupKind {
  household('🏠'),
  roommates('🛋️'),
  trip('🧳'),
  other('👥');

  const GroupKind(this.emoji);

  final String emoji;

  static GroupKind fromName(Object? name) =>
      values.firstWhere((k) => k.name == name, orElse: () => GroupKind.other);
}

class GroupMember extends Equatable {
  final String uid;
  final String name;

  const GroupMember({required this.uid, required this.name});

  @override
  List<Object?> get props => [uid, name];
}

/// A shared budget: household, roommates, a trip with friends.
class SpendingGroup extends Equatable {
  final String id;
  final String name;
  final GroupKind kind;
  final String ownerUid;
  final List<GroupMember> members;

  /// Shared monthly budget in INR, optional.
  final double? monthlyBudget;

  /// Current invite code (6 chars), or `null` when invites are closed.
  final String? inviteCode;
  final DateTime createdAt;

  const SpendingGroup({
    required this.id,
    required this.name,
    required this.kind,
    required this.ownerUid,
    required this.members,
    this.monthlyBudget,
    this.inviteCode,
    required this.createdAt,
  });

  List<String> get memberUids => [for (final m in members) m.uid];

  String nameOf(String uid) =>
      members.where((m) => m.uid == uid).firstOrNull?.name ?? '—';

  bool isMember(String uid) => members.any((m) => m.uid == uid);

  @override
  List<Object?> get props => [
    id,
    name,
    kind,
    ownerUid,
    members,
    monthlyBudget,
    inviteCode,
    createdAt,
  ];
}

/// Who paid and how it's shared. Amounts in INR, rounded to paise.
class GroupExpense extends Equatable {
  final String id;
  final String title;
  final double amount;
  final String paidBy;

  /// uid → share. Sums to [amount].
  final Map<String, double> shares;
  final String? categoryId;
  final DateTime date;
  final String createdBy;
  final DateTime createdAt;

  const GroupExpense({
    required this.id,
    required this.title,
    required this.amount,
    required this.paidBy,
    required this.shares,
    this.categoryId,
    required this.date,
    required this.createdBy,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
    id,
    title,
    amount,
    paidBy,
    shares,
    categoryId,
    date,
    createdBy,
    createdAt,
  ];
}

/// "A paid B back" — clears balances without being an expense.
class GroupSettlement extends Equatable {
  final String id;
  final String from;
  final String to;
  final double amount;
  final DateTime date;
  final String createdBy;

  const GroupSettlement({
    required this.id,
    required this.from,
    required this.to,
    required this.amount,
    required this.date,
    required this.createdBy,
  });

  @override
  List<Object?> get props => [id, from, to, amount, date, createdBy];
}
