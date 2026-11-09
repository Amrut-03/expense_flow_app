import 'package:equatable/equatable.dart';

enum RecurrenceFrequency {
  daily,
  weekly,
  monthly,
  yearly;

  static RecurrenceFrequency fromName(String name) {
    return RecurrenceFrequency.values.firstWhere(
      (f) => f.name == name,
      orElse: () => RecurrenceFrequency.monthly,
    );
  }
}

/// A rule that produces an expense on a fixed schedule (rent, EMI, Netflix…).
///
/// Occurrences are always computed from [startDate] plus [generatedCount]
/// periods, never by adding to the previous date, so month-end anchors don't
/// drift (a rule starting Jan 31 lands on Feb 28, then back on Mar 31).
class RecurringExpenseEntity extends Equatable {
  final String id;
  final String? title;
  final String? merchant;

  /// Amount per occurrence in INR.
  final double amount;

  /// Currency the user pays in.
  final String currency;

  /// Amount per occurrence in [currency].
  final double? originalAmount;

  /// INR per 1 unit of [currency] captured when the rule was created.
  final double? exchangeRate;
  final String categoryId;
  final String? paymentMethod;
  final String? note;

  /// Tax section code copied onto every generated expense.
  final String? taxTag;

  final RecurrenceFrequency frequency;

  /// Repeat every [interval] periods (e.g. 2 + weekly = fortnightly).
  final int interval;
  final DateTime startDate;
  final DateTime? endDate;

  /// Number of occurrences already turned into expenses.
  final int generatedCount;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const RecurringExpenseEntity({
    required this.id,
    this.title,
    this.merchant,
    required this.amount,
    required this.currency,
    this.originalAmount,
    this.exchangeRate,
    required this.categoryId,
    this.paymentMethod,
    this.note,
    this.taxTag,
    required this.frequency,
    this.interval = 1,
    required this.startDate,
    this.endDate,
    this.generatedCount = 0,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  RecurringExpenseEntity copyWith({
    int? generatedCount,
    bool? isActive,
    DateTime? updatedAt,
  }) {
    return RecurringExpenseEntity(
      id: id,
      title: title,
      merchant: merchant,
      amount: amount,
      currency: currency,
      originalAmount: originalAmount,
      exchangeRate: exchangeRate,
      categoryId: categoryId,
      paymentMethod: paymentMethod,
      note: note,
      taxTag: taxTag,
      frequency: frequency,
      interval: interval,
      startDate: startDate,
      endDate: endDate,
      generatedCount: generatedCount ?? this.generatedCount,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    title,
    merchant,
    amount,
    currency,
    originalAmount,
    exchangeRate,
    categoryId,
    paymentMethod,
    note,
    taxTag,
    frequency,
    interval,
    startDate,
    endDate,
    generatedCount,
    isActive,
    createdAt,
    updatedAt,
  ];
}
