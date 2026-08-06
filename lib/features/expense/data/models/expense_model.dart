import 'package:hive/hive.dart';

import '../../domain/entities/expense_entity.dart';

part 'expense_model.g.dart';

@HiveType(typeId: 0)
class ExpenseModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final double amount;

  @HiveField(2)
  final String currency;

  @HiveField(3)
  final String categoryId;

  @HiveField(4)
  final String? note;

  @HiveField(11)
  final String? title;

  @HiveField(12)
  final String? paymentMethod;

  @HiveField(13)
  final String? serverId;

  @HiveField(5)
  final DateTime date;

  @HiveField(6)
  final DateTime createdAt;

  @HiveField(7)
  final DateTime updatedAt;

  @HiveField(14)
  final DateTime? lastSyncedAt;

  @HiveField(8)
  final int version;

  @HiveField(9)
  final String syncStatus;

  @HiveField(10)
  final bool isDeleted;

  ExpenseModel({
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
    this.syncStatus = 'pending',
    this.isDeleted = false,
  });

  /// Entity -> Model
  factory ExpenseModel.fromEntity(ExpenseEntity entity) {
    return ExpenseModel(
      id: entity.id,
      amount: entity.amount,
      currency: entity.currency,
      categoryId: entity.categoryId,
      note: entity.note,
      title: entity.title,
      paymentMethod: entity.paymentMethod,
      serverId: entity.serverId,
      date: entity.date,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      lastSyncedAt: entity.lastSyncedAt,
      version: entity.version,
      syncStatus: entity.syncStatus.name,
      isDeleted: entity.isDeleted,
    );
  }

  /// JSON -> Model
  factory ExpenseModel.fromJson(Map<String, dynamic> json) {
    return ExpenseModel(
      id: json['id'] as String,
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'] as String,
      categoryId: json['categoryId'] as String,
      note: json['note'] as String?,
      title: json['title'] as String?,
      paymentMethod: json['paymentMethod'] as String?,
      serverId: json['serverId'] as String?,
      date: DateTime.parse(json['date'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      lastSyncedAt: json['lastSyncedAt'] != null
          ? DateTime.parse(json['lastSyncedAt'] as String)
          : null,
      version: (json['version'] as num?)?.toInt() ?? 1,
      syncStatus: json['syncStatus'] as String? ?? 'pending',
      isDeleted: json['isDeleted'] as bool? ?? false,
    );
  }

  /// Model -> JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amount': amount,
      'currency': currency,
      'categoryId': categoryId,
      'note': note,
      'title': title,
      'paymentMethod': paymentMethod,
      'serverId': serverId,
      'date': date.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'lastSyncedAt': lastSyncedAt?.toIso8601String(),
      'version': version,
      'syncStatus': syncStatus,
      'isDeleted': isDeleted,
    };
  }

  /// Model -> Entity
  ExpenseEntity toEntity() {
    return ExpenseEntity(
      id: id,
      amount: amount,
      currency: currency,
      categoryId: categoryId,
      note: note,
      title: title,
      paymentMethod: paymentMethod,
      serverId: serverId,
      date: date,
      createdAt: createdAt,
      updatedAt: updatedAt,
      lastSyncedAt: lastSyncedAt,
      version: version,
      syncStatus: SyncStatus.values.firstWhere(
        (e) => e.name == syncStatus,
        orElse: () => SyncStatus.pending,
      ),
      isDeleted: isDeleted,
    );
  }

  ExpenseModel copyWith({
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
    String? syncStatus,
    bool? isDeleted,
  }) {
    return ExpenseModel(
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
