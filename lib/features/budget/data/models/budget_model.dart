import 'package:hive/hive.dart';
import '../../domain/entities/budget_entity.dart';

part 'budget_model.g.dart';

@HiveType(typeId: 1)
class BudgetModel extends HiveObject {
  @HiveField(0)
  final String categoryId;

  @HiveField(1)
  final double limit;

  @HiveField(2, defaultValue: BudgetPeriod.monthly)
  final BudgetPeriod period;

  @HiveField(3)
  final DateTime? createdAt;

  @HiveField(4)
  final DateTime? updatedAt;

  @HiveField(5)
  final DateTime? lastSyncedAt;

  @HiveField(6, defaultValue: 'pending')
  final String syncStatus;

  @HiveField(7, defaultValue: false)
  final bool isDeleted;

  BudgetModel({
    required this.categoryId,
    required this.limit,
    this.period = BudgetPeriod.monthly,
    this.createdAt,
    this.updatedAt,
    this.lastSyncedAt,
    this.syncStatus = 'pending',
    this.isDeleted = false,
  });

  DateTime get createdAtOrNow =>
      createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);

  DateTime get updatedAtOrNow =>
      updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);

  factory BudgetModel.fromEntity(BudgetEntity entity) {
    final now = DateTime.now();
    return BudgetModel(
      categoryId: entity.categoryId,
      limit: entity.limit,
      period: entity.period,
      createdAt: now,
      updatedAt: now,
    );
  }

  factory BudgetModel.fromJson(Map<String, dynamic> json) {
    return BudgetModel(
      categoryId: json['categoryId'] as String,
      limit: (json['limit'] as num).toDouble(),
      period:
          BudgetPeriod.values.asNameMap()[json['period']] ??
          BudgetPeriod.monthly,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      lastSyncedAt: json['lastSyncedAt'] != null
          ? DateTime.parse(json['lastSyncedAt'] as String)
          : null,
      syncStatus: json['syncStatus'] as String? ?? 'pending',
      isDeleted: json['isDeleted'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'categoryId': categoryId,
      'limit': limit,
      'period': period.name,
      'createdAt': createdAtOrNow.toIso8601String(),
      'updatedAt': updatedAtOrNow.toIso8601String(),
      'lastSyncedAt': lastSyncedAt?.toIso8601String(),
      'syncStatus': syncStatus,
      'isDeleted': isDeleted,
    };
  }

  BudgetEntity toEntity() {
    return BudgetEntity(categoryId: categoryId, limit: limit, period: period);
  }

  BudgetModel copyWith({
    String? categoryId,
    double? limit,
    BudgetPeriod? period,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastSyncedAt,
    String? syncStatus,
    bool? isDeleted,
  }) {
    return BudgetModel(
      categoryId: categoryId ?? this.categoryId,
      limit: limit ?? this.limit,
      period: period ?? this.period,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }
}
