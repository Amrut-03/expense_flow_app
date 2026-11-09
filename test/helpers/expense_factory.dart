import 'package:expense_flow_app/features/expense/domain/entities/expense_entity.dart';

var _seq = 0;

ExpenseEntity expenseOf({
  required double amount,
  required DateTime date,
  String categoryId = 'food',
  String? merchant,
  String? title,
  String? recurringId,
  String? taxTag,
  String? paymentMethod,
  bool isDeleted = false,
}) {
  _seq++;
  return ExpenseEntity(
    id: 'e$_seq',
    amount: amount,
    currency: 'INR',
    categoryId: categoryId,
    merchant: merchant,
    title: title,
    recurringId: recurringId,
    taxTag: taxTag,
    paymentMethod: paymentMethod,
    date: date,
    createdAt: date,
    updatedAt: date,
    isDeleted: isDeleted,
  );
}
