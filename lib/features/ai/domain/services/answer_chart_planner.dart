import '../../../expense/domain/entities/expense_entity.dart';
import '../entities/answer_chart.dart';

/// Decides whether a question deserves a chart and builds it from the
/// user's own data. Keyword-based (English, Hindi, Marathi, Hinglish), so it
/// is instant, offline and can't invent numbers.
abstract final class AnswerChartPlanner {
  /// Categories shown in a breakdown before the rest fold into `other`.
  static const maxSlices = 5;
  static const otherKey = '__other__';

  static const _trendWords = [
    'trend',
    'over time',
    'month by month',
    'monthly',
    'per month',
    'each month',
    'every month',
    'last few months',
    'last 6 months',
    'last six months',
    'past months',
    'compare',
    'comparison',
    'history',
    'increasing',
    'decreasing',
    'going up',
    'going down',
    'har mahine',
    'हर महीने',
    'महीनों',
    'प्रत्येक महिन्या',
    'महिन्यांत',
    'ट्रेंड',
  ];
  static const _dailyWords = [
    'daily',
    'each day',
    'per day',
    'every day',
    'day by day',
    'day-wise',
    'day wise',
    'which day',
    'roz',
    'रोज़',
    'रोज',
    'दररोज',
    'हर दिन',
  ];
  static const _breakdownWords = [
    'breakdown',
    'break down',
    'where',
    'which category',
    'categories',
    'category wise',
    'category-wise',
    'split',
    'share',
    'most',
    'biggest',
    'top',
    'distribution',
    'spend on',
    'spent on',
    'kahan',
    'kaha',
    'कहाँ',
    'कहां',
    'कुठे',
    'किस पर',
    'कशावर',
    'श्रेणी',
  ];
  static const _budgetWords = [
    'budget',
    'budgets',
    'limit',
    'limits',
    'over budget',
    'under budget',
    'बजट',
    'बजेट',
  ];
  static const _spendWords = [
    'spend',
    'spent',
    'spending',
    'expense',
    'expenses',
    'kharch',
    'kharcha',
    'खर्च',
    'cost',
    'paid',
    'pay',
  ];

  static AnswerChart? plan({
    required String question,
    required List<ExpenseEntity> expenses,
    required DateTime now,
    Map<String, double> budgetLimits = const {},
    Map<String, double> budgetSpent = const {},
    Map<String, List<String>> categoryNames = const {},
  }) {
    final q = ' ${question.toLowerCase()} ';
    bool any(List<String> words) => words.any(q.contains);

    final category = _mentionedCategory(q, categoryNames);
    final live = expenses.where((e) => !e.isDeleted).toList();

    if (any(_budgetWords) && budgetLimits.isNotEmpty) {
      final points = [
        for (final e in budgetLimits.entries)
          if (e.value > 0 && (category == null || e.key == category))
            AnswerChartPoint(e.key, budgetSpent[e.key] ?? 0, limit: e.value),
      ]..sort((a, b) => (b.value / b.limit!).compareTo(a.value / a.limit!));
      if (points.isEmpty) return null;
      return AnswerChart(
        kind: AnswerChartKind.budgetUsage,
        period: AnswerChartPeriod.thisMonth,
        points: points.take(6).toList(),
      );
    }

    final mentionsSpend = any(_spendWords) || category != null;
    if (any(_trendWords) && (mentionsSpend || any(_breakdownWords))) {
      return _monthlyTrend(live, now, category);
    }

    final period = _period(q);
    if (any(_dailyWords) && mentionsSpend) {
      return _daily(live, now, period, category);
    }
    if (any(_breakdownWords) && mentionsSpend && category == null) {
      return _breakdown(live, now, period);
    }
    return null;
  }

  static AnswerChartPeriod _period(String q) {
    if (q.contains('last month') ||
        q.contains('previous month') ||
        q.contains('पिछले महीने') ||
        q.contains('मागच्या महिन्या') ||
        q.contains('pichle mahine')) {
      return AnswerChartPeriod.lastMonth;
    }
    if (q.contains('this week') ||
        q.contains('इस हफ्ते') ||
        q.contains('या आठवड्या') ||
        q.contains('is hafte')) {
      return AnswerChartPeriod.thisWeek;
    }
    if (q.contains('this year') ||
        q.contains('इस साल') ||
        q.contains('या वर्षी') ||
        q.contains('is saal')) {
      return AnswerChartPeriod.thisYear;
    }
    return AnswerChartPeriod.thisMonth;
  }

  static (DateTime, DateTime) window(AnswerChartPeriod p, DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    return switch (p) {
      AnswerChartPeriod.thisWeek => (
        today.subtract(Duration(days: today.weekday - 1)),
        today.add(const Duration(days: 1)),
      ),
      AnswerChartPeriod.thisMonth => (
        DateTime(now.year, now.month),
        today.add(const Duration(days: 1)),
      ),
      AnswerChartPeriod.lastMonth => (
        DateTime(now.year, now.month - 1),
        DateTime(now.year, now.month),
      ),
      AnswerChartPeriod.lastSixMonths => (
        DateTime(now.year, now.month - 5),
        DateTime(now.year, now.month + 1),
      ),
      AnswerChartPeriod.thisYear => (
        DateTime(now.year),
        today.add(const Duration(days: 1)),
      ),
    };
  }

  static Iterable<ExpenseEntity> _inWindow(
    List<ExpenseEntity> expenses,
    (DateTime, DateTime) w,
    String? category,
  ) => expenses.where(
    (e) =>
        !e.date.isBefore(w.$1) &&
        e.date.isBefore(w.$2) &&
        (category == null || e.categoryId == category),
  );

  static AnswerChart? _breakdown(
    List<ExpenseEntity> expenses,
    DateTime now,
    AnswerChartPeriod period,
  ) {
    final totals = <String, double>{};
    for (final e in _inWindow(expenses, window(period, now), null)) {
      totals.update(
        e.categoryId,
        (v) => v + e.amount,
        ifAbsent: () => e.amount,
      );
    }
    if (totals.length < 2) return null;
    final sorted = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final points = [
      for (final e in sorted.take(maxSlices)) AnswerChartPoint(e.key, e.value),
    ];
    final rest = sorted.skip(maxSlices).fold<double>(0, (s, e) => s + e.value);
    if (rest > 0) points.add(AnswerChartPoint(otherKey, rest));
    return AnswerChart(
      kind: AnswerChartKind.categoryBreakdown,
      period: period,
      points: points,
    );
  }

  static AnswerChart? _monthlyTrend(
    List<ExpenseEntity> expenses,
    DateTime now,
    String? category,
  ) {
    const period = AnswerChartPeriod.lastSixMonths;
    final totals = <String, double>{
      for (var i = 5; i >= 0; i--)
        _monthKey(DateTime(now.year, now.month - i)): 0,
    };
    for (final e in _inWindow(expenses, window(period, now), category)) {
      totals.update(_monthKey(e.date), (v) => v + e.amount);
    }
    if (totals.values.where((v) => v > 0).length < 2) return null;
    return AnswerChart(
      kind: AnswerChartKind.monthlyTrend,
      period: period,
      categoryId: category,
      points: [
        for (final e in totals.entries) AnswerChartPoint(e.key, e.value),
      ],
    );
  }

  static AnswerChart? _daily(
    List<ExpenseEntity> expenses,
    DateTime now,
    AnswerChartPeriod period,
    String? category,
  ) {
    // A year of daily bars is unreadable; fall back to the month.
    final p = period == AnswerChartPeriod.thisYear
        ? AnswerChartPeriod.thisMonth
        : period;
    final w = window(p, now);
    final totals = <String, double>{};
    for (
      var d = w.$1;
      d.isBefore(w.$2);
      d = DateTime(d.year, d.month, d.day + 1)
    ) {
      totals[_dayKey(d)] = 0;
    }
    for (final e in _inWindow(expenses, w, category)) {
      totals.update(
        _dayKey(e.date),
        (v) => v + e.amount,
        ifAbsent: () => e.amount,
      );
    }
    if (totals.values.every((v) => v == 0)) return null;
    return AnswerChart(
      kind: AnswerChartKind.dailySpend,
      period: p,
      categoryId: category,
      points: [
        for (final e in totals.entries) AnswerChartPoint(e.key, e.value),
      ],
    );
  }

  static String? _mentionedCategory(String q, Map<String, List<String>> names) {
    for (final entry in names.entries) {
      for (final name in entry.value) {
        final n = name.toLowerCase().trim();
        if (n.length < 3) continue;
        if (RegExp(
          '(^|[^\\p{L}])${RegExp.escape(n)}',
          unicode: true,
        ).hasMatch(q)) {
          return entry.key;
        }
      }
    }
    return null;
  }

  static String _monthKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}';

  static String _dayKey(DateTime d) =>
      '${_monthKey(d)}-${d.day.toString().padLeft(2, '0')}';
}
