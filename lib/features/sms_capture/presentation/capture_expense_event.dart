import '../../expense/presentation/bloc/expense_event.dart';
import '../domain/entities/captured_transaction.dart';

/// The expense a reviewed capture becomes. Shared by the review screen and
/// the notification "OK" action so both log identical expenses.
AddExpenseEvent captureToExpenseEvent(
  CapturedTransaction c, {
  required String categoryId,
  required String fallbackTitle,
}) {
  return AddExpenseEvent(
    amount: c.amount,
    currency: 'INR',
    originalAmount: c.amount,
    exchangeRate: 1,
    categoryId: categoryId,
    title: c.merchant ?? fallbackTitle,
    merchant: c.merchant,
    paymentMethod: c.paymentMethod,
    note: c.reference == null ? null : 'Ref ${c.reference}',
    date: c.date,
  );
}
