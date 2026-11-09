import 'package:uuid/uuid.dart';

import '../../../expense/domain/usecases/add_expense_usecase.dart';
import '../entities/group.dart';
import '../repositories/group_repository.dart';
import '../services/split_math.dart';

enum GroupExpenseError { title, amount, payer, shares }

/// Adds a shared expense; optionally logs the current user's share as a
/// personal expense so personal budgets stay right.
class AddGroupExpenseUseCase {
  AddGroupExpenseUseCase(
    this.repository, {
    this.addPersonalExpense,
    DateTime Function()? now,
    String Function()? newId,
  }) : _now = now ?? DateTime.now,
       _newId = newId ?? const Uuid().v4;

  final GroupRepository repository;
  final AddExpenseUseCase? addPersonalExpense;
  final DateTime Function() _now;
  final String Function() _newId;

  Future<GroupExpenseError?> call({
    required SpendingGroup group,
    required String title,
    required double amount,
    required String paidBy,
    required Map<String, double> shares,
    String? categoryId,
    DateTime? date,
    bool addMyShareToMyExpenses = false,
  }) async {
    final me = repository.currentUid;
    if (me == null) throw const GroupException(GroupFailure.notSignedIn);
    if (title.trim().isEmpty) return GroupExpenseError.title;
    if (!amount.isFinite || amount <= 0) return GroupExpenseError.amount;
    if (!group.isMember(paidBy)) return GroupExpenseError.payer;
    final cleaned = {
      for (final e in shares.entries)
        if (SplitMath.toPaise(e.value) > 0) e.key: e.value,
    };
    if (cleaned.isEmpty ||
        !cleaned.keys.every(group.isMember) ||
        !SplitMath.sharesMatch(amount, cleaned)) {
      return GroupExpenseError.shares;
    }

    final now = _now();
    final expense = GroupExpense(
      id: _newId(),
      title: title.trim(),
      amount: amount,
      paidBy: paidBy,
      shares: cleaned,
      categoryId: categoryId,
      date: date ?? now,
      createdBy: me,
      createdAt: now,
    );
    await repository.addExpense(group.id, expense);

    final myShare = cleaned[me];
    final personal = addPersonalExpense;
    if (addMyShareToMyExpenses && personal != null && myShare != null) {
      await personal(
        AddExpenseParams(
          amount: myShare,
          currency: 'INR',
          originalAmount: myShare,
          exchangeRate: 1,
          categoryId: categoryId ?? 'other',
          title: '${expense.title} (${group.name})',
          note: myShare == amount
              ? null
              : 'Your share of ${amount.toStringAsFixed(2)}',
          paymentMethod: 'Other',
          date: expense.date,
        ),
      );
    }
    return null;
  }
}

enum SettlementError { amount, people }

class RecordSettlementUseCase {
  RecordSettlementUseCase(
    this.repository, {
    DateTime Function()? now,
    String Function()? newId,
  }) : _now = now ?? DateTime.now,
       _newId = newId ?? const Uuid().v4;

  final GroupRepository repository;
  final DateTime Function() _now;
  final String Function() _newId;

  Future<SettlementError?> call({
    required SpendingGroup group,
    required String from,
    required String to,
    required double amount,
  }) async {
    final me = repository.currentUid;
    if (me == null) throw const GroupException(GroupFailure.notSignedIn);
    if (!amount.isFinite || SplitMath.toPaise(amount) <= 0) {
      return SettlementError.amount;
    }
    if (from == to || !group.isMember(from) || !group.isMember(to)) {
      return SettlementError.people;
    }
    final now = _now();
    await repository.addSettlement(
      group.id,
      GroupSettlement(
        id: _newId(),
        from: from,
        to: to,
        amount: SplitMath.fromPaise(SplitMath.toPaise(amount)),
        date: now,
        createdBy: me,
      ),
    );
    return null;
  }
}

enum LeaveGroupError { unsettled, ownerWithMembers }

class LeaveGroupUseCase {
  LeaveGroupUseCase(this.repository);

  final GroupRepository repository;

  /// You can leave once you're settled up; the owner leaves last.
  Future<LeaveGroupError?> call({
    required SpendingGroup group,
    required Map<String, double> balances,
  }) async {
    final me = repository.currentUid;
    if (me == null) throw const GroupException(GroupFailure.notSignedIn);
    if (SplitMath.toPaise(balances[me] ?? 0) != 0) {
      return LeaveGroupError.unsettled;
    }
    if (group.ownerUid == me && group.members.length > 1) {
      return LeaveGroupError.ownerWithMembers;
    }
    await repository.leave(group.id);
    return null;
  }
}
