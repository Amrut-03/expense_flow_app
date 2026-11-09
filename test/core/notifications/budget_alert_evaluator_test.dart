import 'package:expense_flow_app/core/notifications/budget_alert_evaluator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const evaluator = BudgetAlertEvaluator();

  group('BudgetAlertEvaluator', () {
    test('returns none below 80%', () {
      final result = evaluator.evaluate(spent: 799, limit: 1000);

      expect(result.level, BudgetAlertLevel.none);
      expect(result.percent, closeTo(79.9, 1e-9));
    });

    test('returns threshold80 at exactly 80%', () {
      final result = evaluator.evaluate(spent: 800, limit: 1000);

      expect(result.level, BudgetAlertLevel.threshold80);
    });

    test('returns threshold80 just under 100%', () {
      final result = evaluator.evaluate(spent: 999.99, limit: 1000);

      expect(result.level, BudgetAlertLevel.threshold80);
    });

    test('returns exceeded at exactly 100%', () {
      final result = evaluator.evaluate(spent: 1000, limit: 1000);

      expect(result.level, BudgetAlertLevel.exceeded);
      expect(result.percent, 100);
    });

    test('returns exceeded above 100%', () {
      final result = evaluator.evaluate(spent: 2500, limit: 1000);

      expect(result.level, BudgetAlertLevel.exceeded);
      expect(result.percent, 250);
    });

    test('ignores a zero or negative limit', () {
      expect(
        evaluator.evaluate(spent: 500, limit: 0).level,
        BudgetAlertLevel.none,
      );
      expect(
        evaluator.evaluate(spent: 500, limit: -10).level,
        BudgetAlertLevel.none,
      );
    });

    test('ignores zero spend', () {
      final result = evaluator.evaluate(spent: 0, limit: 1000);

      expect(result.level, BudgetAlertLevel.none);
      expect(result.percent, 0);
    });
  });
}
