import 'package:expense_flow_app/features/ai/domain/entities/answer_chart.dart';
import 'package:expense_flow_app/features/ai/domain/services/answer_chart_planner.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/expense_factory.dart';

void main() {
  final now = DateTime(2026, 11, 15);
  final names = {
    'food': ['food', 'Food', 'खाना', 'जेवण'],
    'shopping': ['shopping', 'Shopping', 'खरीदारी'],
    'transport': ['transport', 'Transport'],
  };
  final expenses = [
    expenseOf(amount: 500, date: DateTime(2026, 11, 2)),
    expenseOf(amount: 300, date: DateTime(2026, 11, 3), categoryId: 'shopping'),
    expenseOf(amount: 200, date: DateTime(2026, 11, 3), categoryId: 'transport'),
    expenseOf(amount: 900, date: DateTime(2026, 10, 5)),
    expenseOf(amount: 50, date: DateTime(2026, 11, 4), isDeleted: true),
  ];

  AnswerChart? plan(String q, {Map<String, double> limits = const {}}) =>
      AnswerChartPlanner.plan(
        question: q,
        expenses: expenses,
        now: now,
        categoryNames: names,
        budgetLimits: limits,
        budgetSpent: const {'food': 500, 'shopping': 300},
      );

  test('no chart for questions that are not about the data shape', () {
    expect(plan('How can I save more?'), isNull);
    expect(plan('Is it okay to buy a phone?'), isNull);
  });

  test('breakdown for "where did I spend" this month', () {
    final chart = plan('Where did I spend most this month?')!;
    expect(chart.kind, AnswerChartKind.categoryBreakdown);
    expect(chart.period, AnswerChartPeriod.thisMonth);
    expect(chart.points.map((p) => (p.key, p.value)), [
      ('food', 500),
      ('shopping', 300),
      ('transport', 200),
    ]);
  });

  test('breakdown respects "last month" and needs 2+ categories', () {
    expect(plan('Where did I spend last month?'), isNull);
  });

  test('folds the tail into "other" after five slices', () {
    final many = [
      for (var i = 0; i < 7; i++)
        expenseOf(amount: 100.0 + i, date: now, categoryId: 'c$i'),
    ];
    final chart = AnswerChartPlanner.plan(
      question: 'category wise spending',
      expenses: many,
      now: now,
    )!;
    expect(chart.points, hasLength(6));
    expect(chart.points.last.key, AnswerChartPlanner.otherKey);
    expect(chart.points.last.value, 100 + 101);
  });

  test('monthly trend, optionally for one category (Hindi name)', () {
    final all = plan('Show my spending trend')!;
    expect(all.kind, AnswerChartKind.monthlyTrend);
    expect(all.points, hasLength(6));
    expect(all.points.last.key, '2026-11');
    expect(all.points.last.value, 1000);
    expect(all.points[4].value, 900);

    final food = plan('खाना का खर्च हर महीने कैसा रहा?')!;
    expect(food.categoryId, 'food');
    expect(food.points.last.value, 500);
  });

  test('daily spend this month covers each day up to today', () {
    final chart = plan('How much did I spend each day?')!;
    expect(chart.kind, AnswerChartKind.dailySpend);
    expect(chart.points, hasLength(15));
    expect(chart.points[2].key, '2026-11-03');
    expect(chart.points[2].value, 500);
  });

  test('budget usage when budgets exist, worst first', () {
    final chart = plan(
      'Am I within budget?',
      limits: const {'food': 1000, 'shopping': 400},
    )!;
    expect(chart.kind, AnswerChartKind.budgetUsage);
    expect(chart.points.first.key, 'shopping');
    expect(chart.points.first.limit, 400);
    expect(plan('Am I within budget?'), isNull);
  });
}
