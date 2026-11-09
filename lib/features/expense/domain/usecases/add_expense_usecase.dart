import 'package:uuid/uuid.dart';

import '../entities/expense_entity.dart';
import '../repositories/expense_repository.dart';
import '../validation/expense_validator.dart';

class AddExpenseParams {
  /// Optional fixed id. Lets callers such as recurring-expense generation
  /// write idempotently; a fresh UUID is used when omitted.
  final String? id;

  /// Amount in INR (the app's base currency).
  final double amount;

  /// Currency the user paid in.
  final String currency;
  final String categoryId;
  final String? note;
  final String? title;
  final String? merchant;

  /// Amount exactly as entered, in [currency].
  final double? originalAmount;

  /// INR per 1 unit of [currency] at entry time.
  final double? exchangeRate;
  final String? recurringId;

  /// Tax section code, see `TaxSection`.
  final String? taxTag;

  /// Event or trip this expense belongs to, see `SpendingEvent`.
  final String? eventId;
  final String? paymentMethod;
  final DateTime date;

  const AddExpenseParams({
    this.id,
    required this.amount,
    required this.currency,
    required this.categoryId,
    this.note,
    this.title,
    this.merchant,
    this.originalAmount,
    this.exchangeRate,
    this.recurringId,
    this.taxTag,
    this.eventId,
    this.paymentMethod,
    required this.date,
  });
}

class AddExpenseUseCase {
  final ExpenseRepository repository;
  final DateTime Function() _now;
  final String Function() _newId;

  AddExpenseUseCase(
    this.repository, {
    DateTime Function()? now,
    String Function()? newId,
  }) : _now = now ?? DateTime.now,
       _newId = newId ?? const Uuid().v4;

  Future<ExpenseEntity> call(AddExpenseParams params) async {
    _validate(params);

    final now = _now();

    final expense = ExpenseEntity(
      id: params.id ?? _newId(),
      amount: params.amount,
      currency: params.currency,
      categoryId: params.categoryId,
      note: ExpenseValidator.clean(params.note),
      title: ExpenseValidator.clean(params.title),
      merchant: ExpenseValidator.clean(params.merchant),
      originalAmount: params.originalAmount,
      exchangeRate: params.exchangeRate,
      recurringId: params.recurringId,
      taxTag: params.taxTag,
      eventId: params.eventId,
      paymentMethod: params.paymentMethod,
      date: params.date,
      createdAt: now,
      updatedAt: now,
      version: 1,
      syncStatus: SyncStatus.pending,
      isDeleted: false,
    );

    await repository.addExpense(expense);

    return expense;
  }

  void _validate(AddExpenseParams params) {
    ExpenseValidator.validate(
      amount: params.amount,
      categoryId: params.categoryId,
      note: params.note,
      title: params.title,
      merchant: params.merchant,
      originalAmount: params.originalAmount,
      exchangeRate: params.exchangeRate,
    );

    final oldestAllowed = _now().subtract(const Duration(days: 365 * 10));

    if (params.date.isBefore(oldestAllowed)) {
      throw Exception('Date is too old');
    }
  }
}
