import 'package:equatable/equatable.dart';

import '../entities/savings_goal.dart';

enum GoalPace {
  /// No target date, so there is no schedule to compare against.
  noDeadline,
  onTrack,
  behind,
  complete,

  /// Target date passed before the goal was reached.
  overdue,
}

class GoalProgress extends Equatable {
  final double saved;
  final double remaining;

  /// 0–100, capped at 100.
  final double percent;
  final GoalPace pace;

  /// Calendar days until the target date (including today); `null` without
  /// a deadline.
  final int? daysLeft;

  /// Amount to put aside per day / month to finish on time.
  final double? perDay;
  final double? perMonth;

  const GoalProgress({
    required this.saved,
    required this.remaining,
    required this.percent,
    required this.pace,
    this.daysLeft,
    this.perDay,
    this.perMonth,
  });

  static GoalProgress of(SavingsGoal goal, DateTime now) {
    final saved = goal.saved;
    final remaining = (goal.target - saved).clamp(0, double.infinity);
    final percent = goal.target <= 0
        ? 100.0
        : (saved / goal.target * 100).clamp(0, 100).toDouble();

    if (goal.isComplete) {
      return GoalProgress(
        saved: saved,
        remaining: 0,
        percent: 100,
        pace: GoalPace.complete,
      );
    }

    final deadline = goal.targetDate;
    if (deadline == null) {
      return GoalProgress(
        saved: saved,
        remaining: remaining.toDouble(),
        percent: percent,
        pace: GoalPace.noDeadline,
      );
    }

    final daysLeft = _days(now, deadline) + 1;
    if (daysLeft <= 0) {
      return GoalProgress(
        saved: saved,
        remaining: remaining.toDouble(),
        percent: percent,
        pace: GoalPace.overdue,
        daysLeft: 0,
      );
    }

    // Linear schedule from creation to deadline.
    final totalDays = _days(goal.createdAt, deadline) + 1;
    final elapsed = (totalDays - daysLeft).clamp(0, totalDays);
    final expected = totalDays <= 0
        ? goal.target
        : goal.target * elapsed / totalDays;

    final perDay = remaining / daysLeft;
    return GoalProgress(
      saved: saved,
      remaining: remaining.toDouble(),
      percent: percent,
      pace: saved + 0.01 >= expected ? GoalPace.onTrack : GoalPace.behind,
      daysLeft: daysLeft,
      perDay: perDay,
      perMonth: perDay * 30.44,
    );
  }

  static int _days(DateTime a, DateTime b) => DateTime.utc(
    b.year,
    b.month,
    b.day,
  ).difference(DateTime.utc(a.year, a.month, a.day)).inDays;

  @override
  List<Object?> get props => [
    saved,
    remaining,
    percent,
    pace,
    daysLeft,
    perDay,
    perMonth,
  ];
}
