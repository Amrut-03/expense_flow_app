import '../../../../core/constants/expense_category.dart';
import '../../../../core/notifications/amount_formatter.dart';
import '../../../budget/domain/services/budget_progress_calculator.dart';
import '../../../expense/domain/entities/expense_entity.dart';
import '../../../recurring/domain/services/bill_reminder_planner.dart';
import 'spending_calendar.dart';

/// Builds the three factual lines of the weekly digest. Every number comes
/// straight from the user's data, so the template is always correct; the
/// on-device model may only reword these lines (see `DigestFaithfulness`).
abstract final class WeeklyDigestBuilder {
  static const maxLines = 3;

  static List<String> build({
    required List<ExpenseEntity> expenses,
    required List<CategoryBudgetProgress> budgets,
    required List<BillReminder> upcomingBills,
    required DateTime now,
  }) {
    final today = DateTime(now.year, now.month, now.day);
    final weekStart = today.subtract(const Duration(days: 6));
    final prevStart = weekStart.subtract(const Duration(days: 7));
    final tomorrow = today.add(const Duration(days: 1));

    final week = <ExpenseEntity>[];
    var prevTotal = 0.0;
    for (final e in expenses) {
      if (e.isDeleted) continue;
      if (!e.date.isBefore(weekStart) && e.date.isBefore(tomorrow)) {
        week.add(e);
      } else if (!e.date.isBefore(prevStart) && e.date.isBefore(weekStart)) {
        prevTotal += e.amount;
      }
    }

    final lines = <String>[_spendLine(week, prevTotal)];

    final top = _topLine(week);
    if (top != null) lines.add(top);

    final heads = _headsUp(expenses, budgets, upcomingBills, now);
    if (heads != null) lines.add(heads);

    return lines.take(maxLines).toList();
  }

  static String _spendLine(List<ExpenseEntity> week, double prevTotal) {
    final total = week.fold<double>(0, (s, e) => s + e.amount);
    if (total <= 0) return 'No spending logged in the last 7 days.';

    final count = week.length;
    final base =
        'You spent ${formatInr(total)} in the last 7 days across $count '
        'payment${count == 1 ? '' : 's'}';
    if (prevTotal <= 0) return '$base.';

    final change = ((total - prevTotal) / prevTotal * 100).round();
    if (change == 0) return '$base, the same as the week before.';
    return change < 0
        ? '$base, ${-change}% less than the week before.'
        : '$base, $change% more than the week before.';
  }

  static String? _topLine(List<ExpenseEntity> week) {
    if (week.isEmpty) return null;

    final byCategory = <String, double>{};
    for (final e in week) {
      byCategory.update(
        e.categoryId,
        (v) => v + e.amount,
        ifAbsent: () => e.amount,
      );
    }
    final topCategory = byCategory.entries.reduce(
      (a, b) => b.value > a.value ? b : a,
    );
    final biggest = week.reduce((a, b) => b.amount > a.amount ? b : a);
    final where = biggest.merchant ?? biggest.title;

    final label = ExpenseCategories.byId(topCategory.key).label;
    final categoryPart =
        '$label was your biggest category at ${formatInr(topCategory.value)}';
    final largestPart = where == null || where.trim().isEmpty
        ? 'your largest payment was ${formatInr(biggest.amount)}'
        : 'your largest payment was ${formatInr(biggest.amount)} at '
              '${where.trim()}';
    return '$categoryPart; $largestPart.';
  }

  static String? _headsUp(
    List<ExpenseEntity> expenses,
    List<CategoryBudgetProgress> budgets,
    List<BillReminder> bills,
    DateTime now,
  ) {
    final exceeded = budgets
        .where((b) => b.status == BudgetPaceStatus.exceeded)
        .toList();
    if (exceeded.isNotEmpty) {
      final b = exceeded.reduce(
        (a, c) => (c.spent - c.limit) > (a.spent - a.limit) ? c : a,
      );
      return 'Your ${ExpenseCategories.byId(b.categoryId).label} budget is '
          'over by ${formatInr(b.spent - b.limit)}.';
    }

    final atRisk = budgets
        .where(
          (b) =>
              b.status == BudgetPaceStatus.atRisk &&
              b.projectedRunOutDate != null,
        )
        .toList();
    if (atRisk.isNotEmpty) {
      final b = atRisk.reduce(
        (a, c) =>
            c.projectedRunOutDate!.isBefore(a.projectedRunOutDate!) ? c : a,
      );
      final d = b.projectedRunOutDate!;
      return 'At this pace your ${ExpenseCategories.byId(b.categoryId).label} '
          'budget runs out around ${_monthDay(d)}.';
    }

    final soon = bills
        .where((r) => r.dueDate.difference(now) <= const Duration(days: 7))
        .toList();
    if (soon.isNotEmpty) {
      final bill = soon.first;
      return 'Coming up: ${bill.label} ${formatInr(bill.amount)} on '
          '${_monthDay(bill.dueDate)}.';
    }

    final calendar = SpendingCalendar.compute(expenses, now: now);
    if (calendar.currentNoSpendStreak >= 2) {
      return 'You are on a ${calendar.currentNoSpendStreak}-day no-spend '
          'streak. Keep it going!';
    }
    return null;
  }

  static const _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  static String _monthDay(DateTime d) => '${_months[d.month - 1]} ${d.day}';
}

/// Guards model-written text: it may reword the facts but never introduce a
/// number that isn't in them.
abstract final class DigestFaithfulness {
  static final _number = RegExp(r'\d[\d,]*(?:\.\d+)?');

  static Set<String> _numbers(String text) => {
    for (final m in _number.allMatches(text)) m.group(0)!.replaceAll(',', ''),
  };

  /// Cleans [output] into at most [WeeklyDigestBuilder.maxLines] lines, or
  /// returns `null` if it is empty, too long, or mentions numbers absent
  /// from [facts].
  static List<String>? accept(String output, List<String> facts) {
    final lines = output
        .replaceAll(r'\n', '\n')
        .split('\n')
        .map((l) => l.replaceFirst(RegExp(r'^\s*(?:[-*•]|\d+[.)])\s*'), ''))
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();
    if (lines.isEmpty || lines.length > WeeklyDigestBuilder.maxLines) {
      return null;
    }
    final text = lines.join(' ');
    if (text.length > 420) return null;

    final allowed = _numbers(facts.join(' '));
    if (!_numbers(text).every(allowed.contains)) return null;
    return lines;
  }
}
