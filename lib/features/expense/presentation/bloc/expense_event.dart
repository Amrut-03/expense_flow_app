import 'package:equatable/equatable.dart';

import '../../../recurring/domain/entities/recurring_expense_entity.dart';
import '../../domain/entities/expense_entity.dart';

abstract class ExpenseEvent extends Equatable {
  const ExpenseEvent();

  @override
  List<Object?> get props => [];
}

class AddExpenseEvent extends ExpenseEvent {
  /// Amount in INR.
  final double amount;
  final String currency;
  final String categoryId;
  final String? note;
  final String? title;
  final String? merchant;

  /// Amount as entered, in [currency].
  final double? originalAmount;

  /// INR per 1 unit of [currency].
  final double? exchangeRate;
  final String? paymentMethod;
  final DateTime date;

  /// Tax section code, see `TaxSection`.
  final String? taxTag;

  /// Event or trip this expense belongs to.
  final String? eventId;

  /// When set, the expense also starts a recurring rule.
  final RecurrenceFrequency? repeat;

  const AddExpenseEvent({
    required this.amount,
    required this.currency,
    required this.categoryId,
    this.note,
    this.title,
    this.merchant,
    this.originalAmount,
    this.exchangeRate,
    this.paymentMethod,
    required this.date,
    this.taxTag,
    this.eventId,
    this.repeat,
  });

  @override
  List<Object?> get props => [
    amount,
    currency,
    categoryId,
    note,
    title,
    merchant,
    originalAmount,
    exchangeRate,
    paymentMethod,
    date,
    taxTag,
    eventId,
    repeat,
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
