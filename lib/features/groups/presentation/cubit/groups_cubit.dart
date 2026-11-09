import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/logging/app_log_buffer.dart';
import '../../domain/entities/group.dart';
import '../../domain/repositories/group_repository.dart';

class GroupsState extends Equatable {
  final bool loading;
  final bool signedIn;
  final bool failed;
  final List<SpendingGroup> groups;

  const GroupsState({
    this.loading = true,
    this.signedIn = true,
    this.failed = false,
    this.groups = const [],
  });

  @override
  List<Object?> get props => [loading, signedIn, failed, groups];
}

class GroupsCubit extends Cubit<GroupsState> {
  GroupsCubit(this.repository) : super(const GroupsState());

  final GroupRepository repository;
  StreamSubscription<List<SpendingGroup>>? _sub;

  void watch() {
    if (repository.currentUid == null) {
      emit(const GroupsState(loading: false, signedIn: false));
      return;
    }
    _sub?.cancel();
    _sub = repository.watchMyGroups().listen(
      (groups) => emit(GroupsState(loading: false, groups: groups)),
      onError: (Object e, StackTrace st) {
        AppLogBuffer.instance.captureError('groups.watch', e, st);
        emit(GroupsState(loading: false, failed: true, groups: state.groups));
      },
    );
  }

  /// Returns the new group, or throws [GroupException].
  Future<SpendingGroup> create({
    required String name,
    required GroupKind kind,
    double? monthlyBudget,
  }) => _guard(
    () =>
        repository.create(name: name, kind: kind, monthlyBudget: monthlyBudget),
  );

  Future<SpendingGroup> join(String code) =>
      _guard(() => repository.join(code));

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on GroupException {
      rethrow;
    } catch (e, st) {
      AppLogBuffer.instance.captureError('groups.action', e, st);
      throw const GroupException(GroupFailure.network);
    }
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
