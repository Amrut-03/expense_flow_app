import 'package:equatable/equatable.dart';

enum BudgetRolloverMode {
  /// Unspent budget simply expires (default).
  none,

  /// Last period's unspent amount is added to this period's limit.
  carryForward,

  /// Last period's unspent amount is deposited into a savings goal.
  toGoal;

  static BudgetRolloverMode fromName(String? name) => values.firstWhere(
    (m) => m.name == name,
    orElse: () => BudgetRolloverMode.none,
  );
}

class BudgetRolloverSetting extends Equatable {
  final BudgetRolloverMode mode;

  /// Target goal when [mode] is [BudgetRolloverMode.toGoal].
  final String? goalId;

  const BudgetRolloverSetting({
    this.mode = BudgetRolloverMode.none,
    this.goalId,
  });

  static const off = BudgetRolloverSetting();

  Map<String, dynamic> toMap() => {'mode': mode.name, 'goalId': ?goalId};

  static BudgetRolloverSetting fromMap(Object? raw) {
    if (raw is! Map) return off;
    return BudgetRolloverSetting(
      mode: BudgetRolloverMode.fromName(raw['mode'] as String?),
      goalId: raw['goalId'] as String?,
    );
  }

  @override
  List<Object?> get props => [mode, goalId];
}
