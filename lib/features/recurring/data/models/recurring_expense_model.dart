import 'package:hive/hive.dart';

import '../../domain/entities/recurring_expense_entity.dart';

part 'recurring_expense_model.g.dart';

@HiveType(typeId: 5)
class RecurringExpenseModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String? title;

  @HiveField(2)
  final String? merchant;

  @HiveField(3)
  final double amount;

  @HiveField(4)
  final String currency;

  @HiveField(5)
  final double? originalAmount;

  @HiveField(6)
  final double? exchangeRate;

  @HiveField(7)
  final String categoryId;

  @HiveField(8)
  final String? paymentMethod;

  @HiveField(9)
  final String? note;

  /// [RecurrenceFrequency.name]; stored as a string so adding a frequency
  /// never needs a new Hive adapter.
  @HiveField(10)
  final String frequency;

  @HiveField(11)
  final int interval;

  @HiveField(12)
  final DateTime startDate;

  @HiveField(13)
  final DateTime? endDate;

  @HiveField(14)
  final int generatedCount;

  @HiveField(15)
  final bool isActive;

  @HiveField(16)
  final DateTime createdAt;

  @HiveField(17)
  final DateTime updatedAt;

  @HiveField(18)
  final String? taxTag;

  RecurringExpenseModel({
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
    required this.frequency,
    this.interval = 1,
    required this.startDate,
    this.endDate,
    this.generatedCount = 0,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.taxTag,
  });

  factory RecurringExpenseModel.fromEntity(RecurringExpenseEntity entity) {
    return RecurringExpenseModel(
      id: entity.id,
      title: entity.title,
      merchant: entity.merchant,
      amount: entity.amount,
      currency: entity.currency,
      originalAmount: entity.originalAmount,
      exchangeRate: entity.exchangeRate,
      categoryId: entity.categoryId,
      paymentMethod: entity.paymentMethod,
      note: entity.note,
      taxTag: entity.taxTag,
      frequency: entity.frequency.name,
      interval: entity.interval,
      startDate: entity.startDate,
      endDate: entity.endDate,
      generatedCount: entity.generatedCount,
      isActive: entity.isActive,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  RecurringExpenseEntity toEntity() {
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
      frequency: RecurrenceFrequency.fromName(frequency),
      interval: interval < 1 ? 1 : interval,
      startDate: startDate,
      endDate: endDate,
      generatedCount: generatedCount,
      isActive: isActive,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
