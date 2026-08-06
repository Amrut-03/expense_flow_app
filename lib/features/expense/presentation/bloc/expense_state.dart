import 'package:equatable/equatable.dart';

import '../../domain/entities/expense_entity.dart';

sealed class ExpenseState extends Equatable {
  const ExpenseState();

  @override
  List<Object?> get props => [];
}

class ExpenseInitial extends ExpenseState {
  const ExpenseInitial();
}

class ExpenseLoading extends ExpenseState {
  const ExpenseLoading();
}

class ExpenseLoaded extends ExpenseState {
  final List<ExpenseEntity> expenses;

  /// Set when local data was loaded/saved but the cloud sync failed
  /// (e.g. offline). Data is still shown; this just flags the sync issue.
  final String? syncWarning;

  const ExpenseLoaded(this.expenses, {this.syncWarning});

  @override
  List<Object?> get props => [expenses, syncWarning];
}

class ExpenseFailure extends ExpenseState {
  final String message;

  const ExpenseFailure(this.message);

  @override
  List<Object?> get props => [message];
}
