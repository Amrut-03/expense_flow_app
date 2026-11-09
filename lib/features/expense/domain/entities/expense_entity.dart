import 'package:equatable/equatable.dart';

enum SyncStatus { pending, synced, failed, conflict }

class ExpenseEntity extends Equatable {
  final String id;

  /// Amount in the app's base currency (INR). All aggregation uses this.
  final double amount;

  /// Currency the user originally paid in (ISO 4217 code).
  final String currency;
  final String categoryId;
  final String? note;
  final String? title;

  /// Merchant or payee, e.g. `Swiggy`. Distinct from [title], which is the
  /// user's own description of the expense.
  final String? merchant;

  /// Amount exactly as entered, in [currency]. `null` on records created
  /// before this field existed.
  final double? originalAmount;

  /// INR per 1 unit of [currency] at the time the expense was recorded.
  final double? exchangeRate;

  /// Id of the recurring rule that generated this expense, if any.
  final String? recurringId;

  /// Indian income-tax section this expense counts towards (`80C`, `80D`,
  /// `HRA`, `80G`, `80E`), see `TaxSection`.
  final String? taxTag;

  /// Id of the event or trip (`SpendingEvent`) this expense belongs to.
  final String? eventId;
  final String? paymentMethod;
  final String? serverId;
  final DateTime date;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastSyncedAt;
  final int version;
  final SyncStatus syncStatus;
  final bool isDeleted;

  const ExpenseEntity({
    required this.id,
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
    this.serverId,
    required this.date,
    required this.createdAt,
    required this.updatedAt,
    this.lastSyncedAt,
    this.version = 1,
    this.syncStatus = SyncStatus.pending,
    this.isDeleted = false,
  });

  @override
  List<Object?> get props => [
    id,
    amount,
    currency,
    categoryId,
    note,
    title,
    merchant,
    originalAmount,
    exchangeRate,
    recurringId,
    taxTag,
    eventId,
    paymentMethod,
    serverId,
    date,
    createdAt,
    updatedAt,
    lastSyncedAt,
    version,
    syncStatus,
    isDeleted,
  ];

  ExpenseEntity copyWith({
    String? id,
    double? amount,
    String? currency,
    String? categoryId,
    String? note,
    String? title,
    String? merchant,
    double? originalAmount,
    double? exchangeRate,
    String? recurringId,
    String? taxTag,
    bool clearTaxTag = false,
    String? eventId,
    bool clearEventId = false,
    String? paymentMethod,
    String? serverId,
    DateTime? date,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastSyncedAt,
    int? version,
    SyncStatus? syncStatus,
    bool? isDeleted,
  }) {
    return ExpenseEntity(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      categoryId: categoryId ?? this.categoryId,
      note: note ?? this.note,
      title: title ?? this.title,
      merchant: merchant ?? this.merchant,
      originalAmount: originalAmount ?? this.originalAmount,
      exchangeRate: exchangeRate ?? this.exchangeRate,
      recurringId: recurringId ?? this.recurringId,
      taxTag: clearTaxTag ? null : (taxTag ?? this.taxTag),
      eventId: clearEventId ? null : (eventId ?? this.eventId),
      paymentMethod: paymentMethod ?? this.paymentMethod,
      serverId: serverId ?? this.serverId,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      version: version ?? this.version,
      syncStatus: syncStatus ?? this.syncStatus,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  /// The amount in the currency it was paid in. Falls back to the INR
  /// [amount] for legacy records that predate [originalAmount].
  double get paidAmount => originalAmount ?? amount;

  /// Whether the expense was paid in a currency other than INR.
  bool get isForeignCurrency =>
      originalAmount != null && currency.toUpperCase() != 'INR';
}
