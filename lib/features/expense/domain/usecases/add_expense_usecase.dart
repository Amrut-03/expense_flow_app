import 'package:uuid/uuid.dart';

import '../../../../core/constants/note_limits.dart';
import '../entities/expense_entity.dart';
import '../repositories/expense_repository.dart';

class AddExpenseParams {
  final double amount;
  final String currency;
  final String categoryId;
  final String? note;
  final String? title;
  final String? paymentMethod;
  final DateTime date;

  const AddExpenseParams({
    required this.amount,
    required this.currency,
    required this.categoryId,
    this.note,
    this.title,
    this.paymentMethod,
    required this.date,
  });
}

class AddExpenseUseCase {
  final ExpenseRepository repository;

  const AddExpenseUseCase(this.repository);

  Future<ExpenseEntity> call(AddExpenseParams params) async {
    _validate(params);

    final now = DateTime.now();

    final expense = ExpenseEntity(
      id: const Uuid().v4(),
      amount: params.amount, // already in INR
      currency: params.currency,
      categoryId: params.categoryId,
      note: params.note?.trim().isEmpty == true ? null : params.note?.trim(),
      title: params.title?.trim().isEmpty == true ? null : params.title?.trim(),
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
    if (params.amount <= 0) {
      throw Exception("Amount must be greater than 0");
    }

    final cents = (params.amount * 100).round();

    if ((params.amount - cents / 100).abs() > 1e-6) {
      throw Exception("Amount can have maximum 2 decimal places");
    }

    if (params.amount > 1000000) {
      throw Exception("Amount exceeds allowed limit");
    }

    if (params.categoryId.trim().isEmpty) {
      throw Exception("Category is required");
    }

    if ((params.note?.length ?? 0) > NoteLimits.maxLength) {
      throw Exception(
        'Note cannot exceed ${NoteLimits.maxLength} characters',
      );
    }

    if ((params.title?.length ?? 0) > NoteLimits.titleMaxLength) {
      throw Exception(
        'Title cannot exceed ${NoteLimits.titleMaxLength} characters',
      );
    }

    final oldestAllowed = DateTime.now().subtract(
      const Duration(days: 365 * 10),
    );

    if (params.date.isBefore(oldestAllowed)) {
      throw Exception("Date is too old");
    }
  }
}
