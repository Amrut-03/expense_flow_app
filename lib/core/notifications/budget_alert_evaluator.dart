/// How far a category's spend is against its budget.
enum BudgetAlertLevel { none, threshold80, exceeded }

/// Outcome of evaluating a category's spend against its budget limit.
class BudgetAlertResult {
  final BudgetAlertLevel level;
  final double spent;
  final double limit;
  final double percent;

  const BudgetAlertResult({
    required this.level,
    required this.spent,
    required this.limit,
    required this.percent,
  });
}

/// Pure, framework-free evaluation of the budget thresholds used by local
/// notifications: an 80% heads-up and a 100% exceeded alert.
///
/// Kept as a standalone class so the threshold logic is trivially unit
/// testable and reused by any future trigger (widget, bloc, server).
class BudgetAlertEvaluator {
  const BudgetAlertEvaluator();

  BudgetAlertResult evaluate({required double spent, required double limit}) {
    if (limit <= 0 || spent <= 0) {
      return BudgetAlertResult(
        level: BudgetAlertLevel.none,
        spent: spent,
        limit: limit,
        percent: 0,
      );
    }

    final percent = spent / limit * 100;

    final level = percent >= 100
        ? BudgetAlertLevel.exceeded
        : percent >= 80
        ? BudgetAlertLevel.threshold80
        : BudgetAlertLevel.none;

    return BudgetAlertResult(
      level: level,
      spent: spent,
      limit: limit,
      percent: percent,
    );
  }
}
