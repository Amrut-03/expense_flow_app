import 'package:uuid/uuid.dart';

import '../../../expense/domain/entities/expense_entity.dart';
import '../../../expense/domain/usecases/add_expense_usecase.dart';
import '../entities/recurring_expense_entity.dart';
import '../repositories/recurring_expense_repository.dart';

/// Creates a recurring rule from a new expense and records that expense as
/// the rule's first occurrence.
class StartRecurringExpenseUseCase {
  StartRecurringExpenseUseCase({
    required this.repository,
    required this.addExpense,
    DateTime Function()? now,
    String Function()? newId,
  }) : _now = now ?? DateTime.now,
       _newId = newId ?? const Uuid().v4;

  final RecurringExpenseRepository repository;
  final AddExpenseUseCase addExpense;
  final DateTime Function() _now;
  final String Function() _newId;

  /// Expense id used for occurrence [index] of rule [ruleId]. Deterministic,
  /// so regenerating the same occurrence overwrites rather than duplicates.
  static String occurrenceId(String ruleId, int index) => '${ruleId}_$index';

  Future<ExpenseEntity> call({
    required AddExpenseParams firstExpense,
    required RecurrenceFrequency frequency,
    int interval = 1,
    DateTime? endDate,
  }) async {
    if (interval < 1) {
      throw ArgumentError.value(interval, 'interval', 'Must be at least 1');
    }

    final now = _now();
    final ruleId = _newId();

    final rule = RecurringExpenseEntity(
      id: ruleId,
      title: firstExpense.title,
      merchant: firstExpense.merchant,
      amount: firstExpense.amount,
      currency: firstExpense.currency,
      originalAmount: firstExpense.originalAmount,
      exchangeRate: firstExpense.exchangeRate,
      categoryId: firstExpense.categoryId,
      paymentMethod: firstExpense.paymentMethod,
      note: firstExpense.note,
      taxTag: firstExpense.taxTag,
      frequency: frequency,
      interval: interval,
      startDate: firstExpense.date,
      endDate: endDate,
      generatedCount: 1,
      createdAt: now,
      updatedAt: now,
    );

    // Validates the expense before the rule is persisted.
    final expense = await addExpense(
      AddExpenseParams(
        id: occurrenceId(ruleId, 0),
        amount: firstExpense.amount,
        currency: firstExpense.currency,
        categoryId: firstExpense.categoryId,
        note: firstExpense.note,
        title: firstExpense.title,
        merchant: firstExpense.merchant,
        originalAmount: firstExpense.originalAmount,
        exchangeRate: firstExpense.exchangeRate,
        recurringId: ruleId,
        paymentMethod: firstExpense.paymentMethod,
        taxTag: firstExpense.taxTag,
        eventId: firstExpense.eventId,
        date: firstExpense.date,
      ),
    );

    await repository.save(rule);

    return expense;
  }
}
