import 'package:equatable/equatable.dart';

import '../../../../core/constants/expense_category.dart';
import '../../../../core/notifications/amount_formatter.dart';
import '../../../budget/domain/services/budget_progress_calculator.dart';
import '../../../budget/domain/usecases/get_budget_insights_usecase.dart';
import '../../../categories/domain/services/category_suggester.dart';
import '../../../expense/domain/entities/expense_entity.dart';
import '../../../goals/domain/entities/savings_goal.dart';
import '../../../goals/domain/services/goal_progress.dart';

/// A parsed "Can I afford ₹X (for Y)?" question.
class AffordabilityQuestion extends Equatable {
  /// `null` when the question asks about affordability but names no price.
  final double? amount;
  final String? categoryId;

  const AffordabilityQuestion({this.amount, this.categoryId});

  @override
  List<Object?> get props => [amount, categoryId];

  static final _intent = RegExp(
    r"\b(?:can|could|should)\s+i\s+(?:afford|buy|get|spend|purchase)\b|"
    r'\bafford(?:able)?\b|'
    r'\b(?:le|kharid|khareed|ghevu|gheu)\s*(?:sakta|sakti|sakte|shakto|shakte)\b|'
    r'\bparvad|'
    r'ले\s*सकत|खरीद\s*सकत|अफोर्ड|घेऊ\s*शकत|परवड',
    caseSensitive: false,
    unicode: true,
  );

  // Amount with an optional currency marker before and unit after.
  static final _amount = RegExp(
    r'(₹|\brs\.?|\binr|\brupees?|रुपये|रुपए|रु\.?)?\s*'
    r'(\d[\d,]*(?:\.\d+)?)\s*'
    r'(k\b|thousand|hazar|hajar|हजार|lakhs?|lacs?|लाख|crore|cr\b|'
    r'₹|rs\b|rupees?|रुपये|रुपए)?',
    caseSensitive: false,
    unicode: true,
  );

  static const _keywords = <String, List<String>>{
    'shopping': [
      'phone',
      'mobile',
      'iphone',
      'laptop',
      'watch',
      'shoes',
      'clothes',
      'dress',
      'jacket',
      'headphones',
      'earbuds',
      'tv',
      'fridge',
      'bag',
      'gift',
      'saree',
      'kurta',
    ],
    'food': [
      'dinner',
      'lunch',
      'breakfast',
      'pizza',
      'restaurant',
      'party',
      'biryani',
      'food',
      'cafe',
      'coffee',
    ],
    'travel': [
      'trip',
      'flight',
      'vacation',
      'holiday',
      'hotel',
      'goa',
      'tour',
      'train ticket',
    ],
    'entertainment': ['movie', 'concert', 'game', 'ps5', 'netflix', 'show'],
    'transport': ['bike', 'scooter', 'cab', 'uber', 'ola', 'petrol'],
    'health': ['gym', 'doctor', 'medicine', 'checkup'],
    'education': ['course', 'book', 'books', 'class', 'tuition'],
  };

  /// Cheap intent check, before loading any data.
  static bool matches(String question) =>
      _intent.hasMatch(_westernDigits(question));

  /// Returns `null` when [question] is not about affordability.
  static AffordabilityQuestion? parse(
    String question, {
    List<ExpenseEntity> history = const [],
  }) {
    final text = _westernDigits(question);
    if (!_intent.hasMatch(text)) return null;

    return AffordabilityQuestion(
      amount: _parseAmount(text),
      categoryId: _category(text, history),
    );
  }

  static double? _parseAmount(String text) {
    double? marked;
    double? largest;

    for (final m in _amount.allMatches(text)) {
      final raw = double.tryParse(m.group(2)!.replaceAll(',', ''));
      if (raw == null) continue;
      final unit = (m.group(3) ?? '').toLowerCase();
      final value = raw * _multiplier(unit);
      final hasMarker =
          m.group(1) != null || (unit.isNotEmpty && _multiplier(unit) == 1);

      if (hasMarker || _multiplier(unit) > 1) {
        marked ??= value;
      } else if (largest == null || value > largest) {
        largest = value;
      }
    }

    if (marked != null) return marked;
    // A bare small number is more likely a model ("iPhone 15") than a price.
    return largest != null && largest >= 100 ? largest : null;
  }

  static double _multiplier(String unit) {
    if (unit.startsWith('k') ||
        unit.startsWith('thousand') ||
        unit.startsWith('ha') ||
        unit == 'हजार') {
      return 1000;
    }
    if (unit.startsWith('lakh') || unit.startsWith('lac') || unit == 'लाख') {
      return 100000;
    }
    if (unit.startsWith('cr')) return 10000000;
    return 1;
  }

  static String? _category(String text, List<ExpenseEntity> history) {
    final lower = text.toLowerCase();
    for (final entry in _keywords.entries) {
      for (final word in entry.value) {
        if (RegExp('\\b${RegExp.escape(word)}\\b').hasMatch(lower)) {
          return entry.key;
        }
      }
    }
    return CategorySuggester.suggest(title: text, history: history)?.categoryId;
  }

  static String _westernDigits(String s) {
    const devanagari = '०१२३४५६७८९';
    final out = StringBuffer();
    for (final ch in s.split('')) {
      final i = devanagari.indexOf(ch);
      out.write(i >= 0 ? '$i' : ch);
    }
    return out.toString();
  }
}

/// Answers affordability questions from budgets, upcoming bills, spending
/// history and savings goals. Deterministic: numbers in the answer always
/// come from the user's data, never from a language model.
abstract final class AffordabilityAdvisor {
  static const disclaimer =
      'This is based on your budgets and recorded expenses only, not your '
      'income or bank balance.';

  static const askForPrice =
      'Tell me the price and I\'ll check it against your budgets, e.g. '
      '"Can I afford a ₹5,000 phone?"';

  static String answer({
    required AffordabilityQuestion question,
    required BudgetInsights insights,
    required List<ExpenseEntity> expenses,
    required List<SavingsGoal> goals,
    required DateTime now,
  }) {
    final amount = question.amount;
    if (amount == null || amount <= 0) return askForPrice;

    final price = formatInr(amount);
    final lines = <String>[];

    final budget = question.categoryId == null
        ? null
        : insights.budgetFor(question.categoryId!);

    if (budget != null) {
      lines.addAll(_againstBudget(amount, price, budget, insights, now));
    } else if (insights.budgets.isNotEmpty) {
      lines.addAll(_againstAllBudgets(amount, price, question, insights, now));
    } else {
      lines.addAll(_againstHistory(amount, price, expenses, now));
    }

    final goalLine = _goalImpact(amount, goals, now);
    if (goalLine != null) lines.add(goalLine);
    lines.add(disclaimer);
    return lines.join('\n');
  }

  static List<String> _againstBudget(
    double amount,
    String price,
    CategoryBudgetProgress b,
    BudgetInsights insights,
    DateTime now,
  ) {
    final label = ExpenseCategories.byId(b.categoryId).label;
    final bills = insights.billsFor(b, now);
    final free = b.remaining - bills;
    final billsNote = bills > 0
        ? ' after ${formatInr(bills)} of upcoming bills'
        : '';
    final after = free - amount;
    final days = b.daysLeft;

    if (free <= 0) {
      return [
        'Not within budget. Your $label budget has nothing left$billsNote '
            'for this period.',
        'It resets in $days day${days == 1 ? '' : 's'}; waiting until then '
            'keeps you on budget.',
      ];
    }
    if (after < 0) {
      return [
        'Not within budget. Your $label budget has ${formatInr(free)} '
            'left$billsNote, so $price would put it over by '
            '${formatInr(-after)}.',
        'It resets in $days day${days == 1 ? '' : 's'}.',
      ];
    }
    final perDay = days <= 0 ? 0.0 : after / days;
    final verdict = amount <= free * 0.5
        ? 'Yes, you can.'
        : 'Yes, but it\'s tight.';
    return [
      '$verdict Your $label budget has ${formatInr(free)} left$billsNote.',
      'After $price you\'d have ${formatInr(after)} for the next $days '
          'day${days == 1 ? '' : 's'} (about ${formatInr(perDay)} a day).',
    ];
  }

  static List<String> _againstAllBudgets(
    double amount,
    String price,
    AffordabilityQuestion q,
    BudgetInsights insights,
    DateTime now,
  ) {
    var free = 0.0;
    for (final b in insights.budgets) {
      final left = b.remaining - insights.billsFor(b, now);
      if (left > 0) free += left;
    }
    final scope = q.categoryId == null
        ? 'Across your budgets'
        : 'You have no ${ExpenseCategories.byId(q.categoryId!).label} '
              'budget. Across your other budgets';

    if (free - amount < 0) {
      return [
        '$scope you have ${formatInr(free)} left after upcoming bills, so '
            '$price would take you over by ${formatInr(amount - free)}.',
      ];
    }
    return [
      '$scope you have ${formatInr(free)} left after upcoming bills. $price '
          'fits, leaving ${formatInr(free - amount)}.',
    ];
  }

  static List<String> _againstHistory(
    double amount,
    String price,
    List<ExpenseEntity> expenses,
    DateTime now,
  ) {
    final monthStart = DateTime(now.year, now.month);
    final historyStart = DateTime(now.year, now.month - 3);
    var thisMonth = 0.0;
    var history = 0.0;
    final monthsWithData = <int>{};

    for (final e in expenses) {
      if (e.isDeleted) continue;
      if (!e.date.isBefore(monthStart)) {
        thisMonth += e.amount;
      } else if (!e.date.isBefore(historyStart)) {
        history += e.amount;
        monthsWithData.add(e.date.year * 12 + e.date.month);
      }
    }

    if (monthsWithData.isEmpty) {
      return [
        'I don\'t have enough history to judge $price yet. Set a budget for '
            'this category and I can tell you exactly how it fits.',
      ];
    }

    final average = history / monthsWithData.length;
    final total = thisMonth + amount;
    if (total <= average) {
      return [
        'It looks okay. You\'ve spent ${formatInr(thisMonth)} this month; '
            'with $price you\'d be at ${formatInr(total)}, within your usual '
            '${formatInr(average)} a month.',
        'Set a budget for a firmer answer.',
      ];
    }
    final over = ((total - average) / average * 100).round();
    return [
      'Careful. You\'ve spent ${formatInr(thisMonth)} this month; $price '
          'would bring it to ${formatInr(total)}, $over% above your usual '
          '${formatInr(average)} a month.',
    ];
  }

  static String? _goalImpact(
    double amount,
    List<SavingsGoal> goals,
    DateTime now,
  ) {
    for (final goal in goals) {
      final progress = GoalProgress.of(goal, now);
      final perDay = progress.perDay;
      if (progress.pace == GoalPace.complete || perDay == null || perDay <= 0) {
        continue;
      }
      final days = (amount / perDay).ceil();
      return 'For perspective: that\'s about $days day${days == 1 ? '' : 's'} '
          'of saving for your "${goal.name}" goal.';
    }
    return null;
  }
}
