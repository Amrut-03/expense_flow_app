import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:async';
import '../../../../core/error/error_formatter.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/expense_entity.dart';
import '../../domain/usecases/add_expense_usecase.dart';
import '../../domain/usecases/delete_expense_usecase.dart';
import '../../domain/usecases/get_expense_usecase.dart';
import '../../domain/usecases/regenerate_ai_chunks_usecase.dart';
import '../../domain/usecases/update_expense_usecase.dart';
import '../../../sync/domain/usecases/pull_remote_changes_usecase.dart';
import '../../../sync/domain/usecases/push_pending_changes_usecase.dart';
import '../../../sync/domain/usecases/watch_remote_expenses_usecase.dart';
import 'expense_event.dart';
import 'expense_state.dart';

class ExpenseBloc extends Bloc<ExpenseEvent, ExpenseState> {
  final AddExpenseUseCase addExpenseUseCase;
  final GetExpensesUseCase getExpensesUseCase;
  final UpdateExpenseUseCase updateExpenseUseCase;
  final DeleteExpenseUseCase deleteExpenseUseCase;
  final RegenerateAiChunksUseCase regenerateAiChunksUseCase;
  final PushPendingChangesUseCase pushPendingChangesUseCase;
  final PullRemoteChangesUseCase pullRemoteChangesUseCase;
  final WatchRemoteExpensesUseCase watchRemoteExpensesUseCase;
  StreamSubscription<dynamic>? _remoteSubscription;

  ExpenseBloc({
    required this.addExpenseUseCase,
    required this.getExpensesUseCase,
    required this.updateExpenseUseCase,
    required this.deleteExpenseUseCase,
    required this.regenerateAiChunksUseCase,
    required this.pushPendingChangesUseCase,
    required this.pullRemoteChangesUseCase,
    required this.watchRemoteExpensesUseCase,
  }) : super(const ExpenseInitial()) {
    on<AddExpenseEvent>(_onAddExpense);
    on<LoadExpensesEvent>(_onLoadExpenses);
    on<UpdateExpenseEvent>(_onUpdateExpense);
    on<DeleteExpenseEvent>(_onDeleteExpense);
    on<RemoteExpensesUpdated>(_onRemoteExpensesUpdated);
    on<RemoteWatchFailed>(_onRemoteWatchFailed);

    _remoteSubscription = watchRemoteExpensesUseCase().listen(
      (expenses) => add(RemoteExpensesUpdated(expenses)),
      onError: (e) => add(RemoteWatchFailed(friendlyError(e))),
    );
  }

  @override
  Future<void> close() {
    _remoteSubscription?.cancel();
    return super.close();
  }

  Future<void> _onAddExpense(
    AddExpenseEvent event,
    Emitter<ExpenseState> emit,
  ) async {
    try {
      emit(const ExpenseLoading());

      final added = await addExpenseUseCase(
        AddExpenseParams(
          amount: event.amount,
          currency: event.currency,
          categoryId: event.categoryId,
          note: event.note,
          title: event.title,
          paymentMethod: event.paymentMethod,
          date: event.date,
        ),
      );

      final syncFailure = await _pushPending();

      emit(
        ExpenseLoaded(
          _visible(await getExpensesUseCase()),
          syncWarning: _pushWarning(syncFailure),
        ),
      );

      await _refreshAiChunks(added.id);
    } catch (e) {
      emit(ExpenseFailure(friendlyError(e)));
    }
  }

  Future<void> _onLoadExpenses(
    LoadExpensesEvent event,
    Emitter<ExpenseState> emit,
  ) async {
    try {
      emit(const ExpenseLoading());

      final syncFailure = await _pullRemote();

      emit(
        ExpenseLoaded(
          _visible(await getExpensesUseCase()),
          syncWarning: _pullWarning(syncFailure),
        ),
      );
    } catch (e) {
      emit(ExpenseFailure(friendlyError(e)));
    }
  }

  Future<void> _onUpdateExpense(
    UpdateExpenseEvent event,
    Emitter<ExpenseState> emit,
  ) async {
    try {
      emit(const ExpenseLoading());

      await updateExpenseUseCase(event.expense);

      final syncFailure = await _pushPending();

      emit(
        ExpenseLoaded(
          _visible(await getExpensesUseCase()),
          syncWarning: _pushWarning(syncFailure),
        ),
      );

      await _refreshAiChunks(event.expense.id);
    } catch (e) {
      emit(ExpenseFailure(friendlyError(e)));
    }
  }

  Future<void> _onDeleteExpense(
    DeleteExpenseEvent event,
    Emitter<ExpenseState> emit,
  ) async {
    try {
      emit(const ExpenseLoading());

      await deleteExpenseUseCase(event.expenseId);

      final syncFailure = await _pushPending();

      emit(
        ExpenseLoaded(
          _visible(await getExpensesUseCase()),
          syncWarning: _pushWarning(syncFailure),
        ),
      );

      await _refreshAiChunks(event.expenseId);
    } catch (e) {
      emit(ExpenseFailure(friendlyError(e)));
    }
  }

  /// Rebuilds the AI chunks affected by [expenseId].
  ///
  /// Best-effort background indexing: a failure must never break the
  /// expense flow, so errors are captured and discarded here.
  Future<void> _refreshAiChunks(String expenseId) async {
    try {
      await regenerateAiChunksUseCase(expenseId);
    } catch (_) {
      // Index refresh is non-critical; ignore failures.
    }
  }

  List<ExpenseEntity> _visible(List<ExpenseEntity> expenses) =>
      expenses.where((e) => !e.isDeleted).toList();

  Future<void> _onRemoteExpensesUpdated(
    RemoteExpensesUpdated event,
    Emitter<ExpenseState> emit,
  ) async {
    emit(ExpenseLoaded(_visible(event.expenses)));
  }

  Future<void> _onRemoteWatchFailed(
    RemoteWatchFailed event,
    Emitter<ExpenseState> emit,
  ) async {
    emit(ExpenseFailure('Live sync failed: ${event.message}'));
  }

  Future<Failure?> _pullRemote() async {
    final result = await pullRemoteChangesUseCase();
    return result.fold((failure) => failure, (_) => null);
  }

  Future<Failure?> _pushPending() async {
    final result = await pushPendingChangesUseCase();
    return result.fold((failure) => failure, (_) => null);
  }

  String? _pushWarning(Failure? failure) {
    if (failure == null) return null;
    return 'Saved locally. Not synced: ${failure.message}';
  }

  String? _pullWarning(Failure? failure) {
    if (failure == null) return null;
    return 'Showing saved data. Refresh failed: ${failure.message}';
  }
}
