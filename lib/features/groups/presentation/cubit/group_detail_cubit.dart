import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/logging/app_log_buffer.dart';
import '../../domain/entities/group.dart';
import '../../domain/repositories/group_repository.dart';
import '../../domain/services/split_math.dart';
import '../../domain/usecases/group_usecases.dart';

class GroupDetailState extends Equatable {
  final bool loading;

  /// Group deleted or I was removed / left.
  final bool gone;
  final SpendingGroup? group;
  final List<GroupExpense> expenses;
  final List<GroupSettlement> settlements;
  final String? me;
  final DateTime now;

  const GroupDetailState({
    this.loading = true,
    this.gone = false,
    this.group,
    this.expenses = const [],
    this.settlements = const [],
    this.me,
    required this.now,
  });

  Map<String, double> get balances => group == null
      ? const {}
      : SplitMath.balances(
          members: group!.memberUids,
          expenses: expenses,
          settlements: settlements,
        );

  List<Transfer> get suggestions => SplitMath.settleUp(balances);

  double get spentThisMonth => SplitMath.spentThisMonth(expenses, now);

  GroupDetailState copyWith({
    bool? loading,
    bool? gone,
    SpendingGroup? group,
    List<GroupExpense>? expenses,
    List<GroupSettlement>? settlements,
  }) => GroupDetailState(
    loading: loading ?? this.loading,
    gone: gone ?? this.gone,
    group: group ?? this.group,
    expenses: expenses ?? this.expenses,
    settlements: settlements ?? this.settlements,
    me: me,
    now: now,
  );

  @override
  List<Object?> get props => [
    loading,
    gone,
    group,
    expenses,
    settlements,
    me,
    now,
  ];
}

class GroupDetailCubit extends Cubit<GroupDetailState> {
  GroupDetailCubit({
    required this.groupId,
    required this.repository,
    required this.addExpenseUseCase,
    required this.recordSettlement,
    required this.leaveGroup,
    DateTime Function()? now,
  }) : super(
         GroupDetailState(
           me: repository.currentUid,
           now: (now ?? DateTime.now)(),
         ),
       );

  final String groupId;
  final GroupRepository repository;
  final AddGroupExpenseUseCase addExpenseUseCase;
  final RecordSettlementUseCase recordSettlement;
  final LeaveGroupUseCase leaveGroup;
  final _subs = <StreamSubscription<Object?>>[];
  var _groupLoaded = false;

  void watch() {
    void onError(Object e, StackTrace st) {
      AppLogBuffer.instance.captureError('groups.detail', e, st);
      // Permission errors after leaving/removal: treat as gone.
      if (!isClosed) emit(state.copyWith(loading: false, gone: !_groupLoaded));
    }

    _subs.addAll([
      repository.watchGroup(groupId).listen((group) {
        final me = state.me;
        if (group == null || (me != null && !group.isMember(me))) {
          emit(state.copyWith(loading: false, gone: true));
          return;
        }
        _groupLoaded = true;
        emit(state.copyWith(loading: false, group: group));
      }, onError: onError),
      repository
          .watchExpenses(groupId)
          .listen((e) => emit(state.copyWith(expenses: e)), onError: onError),
      repository
          .watchSettlements(groupId)
          .listen(
            (s) => emit(state.copyWith(settlements: s)),
            onError: onError,
          ),
    ]);
  }

  Future<GroupExpenseError?> addExpense({
    required String title,
    required double amount,
    required String paidBy,
    required Map<String, double> shares,
    String? categoryId,
    DateTime? date,
    bool addMyShareToMyExpenses = false,
  }) async {
    final group = state.group;
    if (group == null) return GroupExpenseError.payer;
    return _guard(
      () => addExpenseUseCase(
        group: group,
        title: title,
        amount: amount,
        paidBy: paidBy,
        shares: shares,
        categoryId: categoryId,
        date: date,
        addMyShareToMyExpenses: addMyShareToMyExpenses,
      ),
    );
  }

  Future<SettlementError?> settle({
    required String from,
    required String to,
    required double amount,
  }) async {
    final group = state.group;
    if (group == null) return SettlementError.people;
    return _guard(
      () => recordSettlement(group: group, from: from, to: to, amount: amount),
    );
  }

  Future<void> deleteExpense(String expenseId) =>
      _guard(() => repository.deleteExpense(groupId, expenseId));

  Future<String> invite() => _guard(() => repository.createInvite(groupId));

  Future<void> updateBudget(double? budget) =>
      _guard(() => repository.updateBudget(groupId, budget));

  Future<LeaveGroupError?> leave() async {
    final group = state.group;
    if (group == null) return null;
    return _guard(() => leaveGroup(group: group, balances: state.balances));
  }

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on GroupException {
      rethrow;
    } catch (e, st) {
      AppLogBuffer.instance.captureError('groups.detail.action', e, st);
      throw const GroupException(GroupFailure.network);
    }
  }

  @override
  Future<void> close() {
    for (final s in _subs) {
      s.cancel();
    }
    return super.close();
  }
}
