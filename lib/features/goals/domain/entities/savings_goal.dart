import 'package:equatable/equatable.dart';

class GoalContribution extends Equatable {
  /// Positive to add money, negative to withdraw. INR.
  final double amount;
  final DateTime date;

  const GoalContribution({required this.amount, required this.date});

  Map<String, dynamic> toMap() => {
    'amount': amount,
    'date': date.toIso8601String(),
  };

  static GoalContribution? fromMap(Object? raw) {
    if (raw is! Map) return null;
    final amount = (raw['amount'] as num?)?.toDouble();
    final date = DateTime.tryParse(raw['date'] as String? ?? '');
    if (amount == null || date == null) return null;
    return GoalContribution(amount: amount, date: date);
  }

  @override
  List<Object?> get props => [amount, date];
}

class SavingsGoal extends Equatable {
  final String id;
  final String name;
  final String emoji;

  /// Target in INR.
  final double target;
  final DateTime? targetDate;
  final List<GoalContribution> contributions;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SavingsGoal({
    required this.id,
    required this.name,
    required this.emoji,
    required this.target,
    this.targetDate,
    this.contributions = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  double get saved => contributions.fold(0, (sum, c) => sum + c.amount);

  bool get isComplete => saved >= target;

  SavingsGoal copyWith({
    List<GoalContribution>? contributions,
    DateTime? updatedAt,
  }) {
    return SavingsGoal(
      id: id,
      name: name,
      emoji: emoji,
      target: target,
      targetDate: targetDate,
      contributions: contributions ?? this.contributions,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'emoji': emoji,
    'target': target,
    'targetDate': targetDate?.toIso8601String(),
    'contributions': [for (final c in contributions) c.toMap()],
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  static SavingsGoal? fromMap(Object? raw) {
    if (raw is! Map) return null;
    final id = raw['id'];
    final name = raw['name'];
    final target = (raw['target'] as num?)?.toDouble();
    final createdAt = DateTime.tryParse(raw['createdAt'] as String? ?? '');
    if (id is! String || name is! String || target == null) return null;
    if (createdAt == null) return null;
    final contributions = raw['contributions'];
    return SavingsGoal(
      id: id,
      name: name,
      emoji: raw['emoji'] as String? ?? '🎯',
      target: target,
      targetDate: DateTime.tryParse(raw['targetDate'] as String? ?? ''),
      contributions: contributions is List
          ? contributions
                .map(GoalContribution.fromMap)
                .whereType<GoalContribution>()
                .toList()
          : const [],
      createdAt: createdAt,
      updatedAt:
          DateTime.tryParse(raw['updatedAt'] as String? ?? '') ?? createdAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    emoji,
    target,
    targetDate,
    contributions,
    createdAt,
    updatedAt,
  ];
}
