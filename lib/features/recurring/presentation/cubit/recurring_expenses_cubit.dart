import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/error_formatter.dart';
import '../../domain/entities/recurring_expense_entity.dart';
import '../../domain/usecases/manage_recurring_expenses_usecases.dart';

enum RecurringExpensesStatus { loading, loaded, failure }

class RecurringExpensesState extends Equatable {
  final RecurringExpensesStatus status;
  final List<RecurringExpenseEntity> rules;
  final String? error;

  const RecurringExpensesState({
    this.status = RecurringExpensesStatus.loading,
    this.rules = const [],
    this.error,
  });

  @override
  List<Object?> get props => [status, rules, error];
}

class RecurringExpensesCubit extends Cubit<RecurringExpensesState> {
  RecurringExpensesCubit({
    required this.getRules,
    required WatchRecurringExpensesUseCase watchRules,
    required this.setActiveRule,
    required this.deleteRule,
  }) : super(const RecurringExpensesState()) {
    _subscription = watchRules().listen((_) => load());
  }

  final GetRecurringExpensesUseCase getRules;
  final SetRecurringExpenseActiveUseCase setActiveRule;
  final DeleteRecurringExpenseUseCase deleteRule;
  StreamSubscription<void>? _subscription;

  Future<void> load() async {
    try {
      final rules = await getRules();
      if (isClosed) return;
      emit(
        RecurringExpensesState(
          status: RecurringExpensesStatus.loaded,
          rules: rules,
        ),
      );
    } catch (e) {
      if (isClosed) return;
      emit(
        RecurringExpensesState(
          status: RecurringExpensesStatus.failure,
          rules: state.rules,
          error: friendlyError(e),
        ),
      );
    }
  }

  Future<void> setActive(String id, bool active) async {
    await setActiveRule(id, active: active);
  }

  Future<void> delete(String id) async {
    await deleteRule(id);
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
