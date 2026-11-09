import 'package:equatable/equatable.dart';

enum AnswerChartKind {
  /// Share of spend per category (donut).
  categoryBreakdown,

  /// Spend per month (bars), optionally for one category.
  monthlyTrend,

  /// Spend per day of the period (bars).
  dailySpend,

  /// Spent vs limit per budget (paired bars).
  budgetUsage,
}

enum AnswerChartPeriod {
  thisWeek,
  thisMonth,
  lastMonth,
  lastSixMonths,
  thisYear,
}

class AnswerChartPoint extends Equatable {
  /// Category id, `yyyy-MM`, or `yyyy-MM-dd`, depending on the chart kind.
  final String key;
  final double value;

  /// Second series value (budget limit) for [AnswerChartKind.budgetUsage].
  final double? limit;

  const AnswerChartPoint(this.key, this.value, {this.limit});

  @override
  List<Object?> get props => [key, value, limit];
}

/// A small chart attached to an AI answer. Built from the user's data by
/// code, never from model output, so the numbers are always exact.
class AnswerChart extends Equatable {
  final AnswerChartKind kind;
  final AnswerChartPeriod period;

  /// Set when the chart is about a single category.
  final String? categoryId;
  final List<AnswerChartPoint> points;

  const AnswerChart({
    required this.kind,
    required this.period,
    required this.points,
    this.categoryId,
  });

  double get total => points.fold(0, (s, p) => s + p.value);

  @override
  List<Object?> get props => [kind, period, categoryId, points];
}
