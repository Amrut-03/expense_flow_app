import 'package:equatable/equatable.dart';

enum SyncStatus { pending, synced, failed, conflict }

class ExpenseEntity extends Equatable {
  final String id;
  final double amount;
  final String currency;
  final String categoryId;
  final String? note;
  final String? title;
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
}
