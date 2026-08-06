import 'package:equatable/equatable.dart';

import '../../domain/entities/expense_entity.dart';

abstract class ExpenseEvent extends Equatable {
  const ExpenseEvent();

  @override
  List<Object?> get props => [];
}

class AddExpenseEvent extends ExpenseEvent {
  final double amount;
  final String currency;
  final String categoryId;
  final String? note;
  final String? title;
  final String? paymentMethod;
  final DateTime date;

  const AddExpenseEvent({
    required this.amount,
    required this.currency,
    required this.categoryId,
    this.note,
    this.title,
    this.paymentMethod,
    required this.date,
  });

  @override
  List<Object?> get props => [
    amount,
    currency,
    categoryId,
    note,
    title,
    paymentMethod,
    date,
  ];
}

class LoadExpensesEvent extends ExpenseEvent {
  const LoadExpensesEvent();
}

class UpdateExpenseEvent extends ExpenseEvent {
  final ExpenseEntity expense;

  const UpdateExpenseEvent(this.expense);

  @override
  List<Object?> get props => [expense];
}

class DeleteExpenseEvent extends ExpenseEvent {
  final String expenseId;

  const DeleteExpenseEvent(this.expenseId);

  @override
  List<Object?> get props => [expenseId];
}

class RemoteExpensesUpdated extends ExpenseEvent {
  final List<ExpenseEntity> expenses;

  const RemoteExpensesUpdated(this.expenses);

  @override
  List<Object?> get props => [expenses];
}

class RemoteWatchFailed extends ExpenseEvent {
  final String message;

  const RemoteWatchFailed(this.message);

  @override
  List<Object?> get props => [message];
}
