import 'package:equatable/equatable.dart';

import '../../../expense/domain/entities/expense_entity.dart';

enum SuggestionSource {
  /// Same merchant seen before in the user's own history.
  history,

  /// Shares a distinctive word with a merchant seen before.
  similarHistory,

  /// Matched the built-in dictionary of well-known merchants.
  dictionary,
}

class CategorySuggestion extends Equatable {
  final String categoryId;
  final SuggestionSource source;

  const CategorySuggestion(this.categoryId, this.source);

  @override
  List<Object?> get props => [categoryId, source];
}

/// Suggests a category for a merchant/title, learning from the user's own
/// past expenses first and falling back to well-known Indian merchants.
/// Pure and synchronous so it can run on every keystroke.
abstract final class CategorySuggester {
  static CategorySuggestion? suggest({
    String? merchant,
    String? title,
    required List<ExpenseEntity> history,
    bool Function(String categoryId)? isAvailable,
  }) {
    final available = isAvailable ?? (_) => true;
    final query = normalize(merchant ?? '').isNotEmpty
        ? normalize(merchant!)
        : normalize(title ?? '');
    if (query.isEmpty) return null;

    // 1. Exact merchant match in history: most frequent, then most recent.
    final exact = _vote(
      history.where((e) => !e.isDeleted && _keyOf(e) == query),
      available,
    );
    if (exact != null) {
      return CategorySuggestion(exact, SuggestionSource.history);
    }

    // 2. Shared distinctive token ("swiggy instamart" ~ "swiggy").
    final tokens = _tokens(query);
    if (tokens.isNotEmpty) {
      final similar = _vote(
        history.where(
          (e) => !e.isDeleted && _tokens(_keyOf(e)).any(tokens.contains),
        ),
        available,
      );
      if (similar != null) {
        return CategorySuggestion(similar, SuggestionSource.similarHistory);
      }
    }

    // 3. Dictionary of well-known merchants.
    for (final entry in _dictionary.entries) {
      for (final keyword in entry.value) {
        if (_containsWord(query, keyword) && available(entry.key)) {
          return CategorySuggestion(entry.key, SuggestionSource.dictionary);
        }
      }
    }

    return null;
  }

  /// Lower-cases, strips punctuation and corporate suffixes so
  /// "SWIGGY*Bangalore Pvt. Ltd." and "swiggy" compare equal-ish.
  static String normalize(String raw) {
    var s = raw.toLowerCase().replaceAll(RegExp(r'[^a-z0-9\s]'), ' ');
    s = s.replaceAll(
      RegExp(
        r'\b(pvt|private|ltd|limited|llp|inc|india|in|co|com|www|the|payment|payments|upi)\b',
      ),
      ' ',
    );
    return s.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  static String _keyOf(ExpenseEntity e) =>
      normalize(e.merchant ?? e.title ?? '');

  static Set<String> _tokens(String normalized) => normalized
      .split(' ')
      .where((t) => t.length >= 4 && !RegExp(r'^\d+$').hasMatch(t))
      .toSet();

  static bool _containsWord(String haystack, String word) =>
      RegExp('\\b${RegExp.escape(word)}\\b').hasMatch(haystack);

  static String? _vote(
    Iterable<ExpenseEntity> matches,
    bool Function(String) available,
  ) {
    final counts = <String, int>{};
    final latest = <String, DateTime>{};
    for (final e in matches) {
      if (!available(e.categoryId)) continue;
      counts.update(e.categoryId, (v) => v + 1, ifAbsent: () => 1);
      final seen = latest[e.categoryId];
      if (seen == null || e.date.isAfter(seen)) latest[e.categoryId] = e.date;
    }
    if (counts.isEmpty) return null;

    final ranked = counts.keys.toList()
      ..sort((a, b) {
        final byCount = counts[b]!.compareTo(counts[a]!);
        return byCount != 0 ? byCount : latest[b]!.compareTo(latest[a]!);
      });
    return ranked.first;
  }

  static const Map<String, List<String>> _dictionary = {
    'food': [
      'swiggy',
      'zomato',
      'dominos',
      'domino',
      'pizza',
      'mcdonalds',
      'kfc',
      'starbucks',
      'chaayos',
      'restaurant',
      'cafe',
      'hotel',
      'bakery',
      'eatsure',
      'faasos',
      'burger',
      'biryani',
      'dosa',
      'chai',
      'blinkit',
      'zepto',
      'bigbasket',
      'instamart',
      'dmart',
      'grocery',
      'kirana',
    ],
    'transport': [
      'uber',
      'ola',
      'rapido',
      'metro',
      'bmtc',
      'best',
      'auto',
      'cab',
      'taxi',
      'petrol',
      'diesel',
      'fuel',
      'hpcl',
      'bpcl',
      'indianoil',
      'iocl',
      'fastag',
      'parking',
      'namma yatri',
    ],
    'shopping': [
      'amazon',
      'flipkart',
      'myntra',
      'ajio',
      'meesho',
      'nykaa',
      'tata cliq',
      'croma',
      'reliance digital',
      'decathlon',
      'ikea',
      'lifestyle',
      'westside',
      'zara',
      'h m',
    ],
    'entertainment': [
      'netflix',
      'hotstar',
      'prime video',
      'spotify',
      'gaana',
      'jiosaavn',
      'youtube',
      'bookmyshow',
      'pvr',
      'inox',
      'sonyliv',
      'zee5',
      'steam',
      'playstation',
    ],
    'bills': [
      'airtel',
      'jio',
      'vodafone',
      'vi',
      'bsnl',
      'electricity',
      'bescom',
      'msedcl',
      'tata power',
      'adani',
      'water',
      'gas',
      'broadband',
      'act',
      'recharge',
      'rent',
      'maintenance',
      'insurance',
      'lic',
      'dth',
      'tata play',
    ],
    'health': [
      'apollo',
      'pharmeasy',
      '1mg',
      'netmeds',
      'medplus',
      'pharmacy',
      'chemist',
      'hospital',
      'clinic',
      'diagnostic',
      'lab',
      'practo',
      'cult',
      'gym',
    ],
    'travel': [
      'irctc',
      'makemytrip',
      'goibibo',
      'cleartrip',
      'yatra',
      'redbus',
      'indigo',
      'air india',
      'vistara',
      'akasa',
      'spicejet',
      'oyo',
      'airbnb',
      'booking',
      'agoda',
      'ixigo',
    ],
    'education': [
      'byju',
      'byjus',
      'unacademy',
      'udemy',
      'coursera',
      'vedantu',
      'school',
      'college',
      'tuition',
      'books',
      'stationery',
      'kindle',
    ],
  };
}
