import '../../../categories/domain/services/category_suggester.dart';
import '../../../expense/domain/entities/expense_entity.dart';
import '../entities/voice_expense_draft.dart';

/// Rule-based extraction of an expense from an English, Hindi or Marathi
/// transcript ("चहा 20 रुपये", "petrol 500 cash", "Swiggy ला 250 UPI").
///
/// Instant and offline; the on-device model may refine the result later.
abstract final class VoiceExpenseParser {
  static VoiceExpenseDraft parse(
    String transcript, {
    List<ExpenseEntity> history = const [],
    bool Function(String categoryId)? isAvailable,
  }) {
    final available = isAvailable ?? (_) => true;
    final text = normalizeDigits(transcript).trim();
    if (text.isEmpty) return VoiceExpenseDraft(transcript: transcript);

    final lower = text.toLowerCase();
    final amount = _amount(lower);
    final payment = _match(lower, _paymentWords);

    final merchant = _merchant(_withoutPaymentWords(text), history, available);
    String? category;
    if (merchant != null) {
      category = CategorySuggester.suggest(
        merchant: merchant,
        history: history,
        isAvailable: available,
      )?.categoryId;
    }
    category ??= _keywordCategory(lower, available);

    final title = _title(text, amount?.span, merchant);

    return VoiceExpenseDraft(
      transcript: transcript,
      amount: amount?.value,
      amountIsInr: amount?.isInr ?? false,
      title: title,
      merchant: merchant,
      categoryId: category,
      paymentMethod: payment,
    );
  }

  /// Devanagari digits → ASCII.
  static String normalizeDigits(String s) {
    final out = StringBuffer();
    for (final r in s.runes) {
      out.writeCharCode(r >= 0x0966 && r <= 0x096F ? r - 0x0966 + 0x30 : r);
    }
    return out.toString();
  }

  /// Every number mentioned (after multipliers), for validating model output.
  static List<double> numbersIn(String transcript) {
    final lower = normalizeDigits(transcript).toLowerCase();
    return [for (final c in _candidates(lower)) c.value];
  }

  // ---------------------------------------------------------------- amount

  static const _currency = [
    '₹',
    'rs',
    'rs.',
    'inr',
    'rupee',
    'rupees',
    'rupay',
    'rupaye',
    'rupiya',
    'रुपये',
    'रुपए',
    'रुपया',
    'रुपयांचा',
    'रुपयांची',
    'रुपयाचे',
    'रुपयांचे',
    'रु',
    'रू',
    'रुपै',
  ];

  static const _multipliers = {
    'hundred': 100.0,
    'सौ': 100.0,
    'शंभर': 100.0,
    'शे': 100.0,
    'thousand': 1000.0,
    'k': 1000.0,
    'hazar': 1000.0,
    'hajar': 1000.0,
    'हज़ार': 1000.0,
    'हजार': 1000.0,
    'lakh': 100000.0,
    'लाख': 100000.0,
  };

  static const _numberWords = {
    'one': 1.0,
    'two': 2.0,
    'three': 3.0,
    'four': 4.0,
    'five': 5.0,
    'six': 6.0,
    'seven': 7.0,
    'eight': 8.0,
    'nine': 9.0,
    'ten': 10.0,
    'twenty': 20.0,
    'thirty': 30.0,
    'forty': 40.0,
    'fifty': 50.0,
    'एक': 1.0,
    'दो': 2.0,
    'दोन': 2.0,
    'तीन': 3.0,
    'चार': 4.0,
    'पांच': 5.0,
    'पाँच': 5.0,
    'पाच': 5.0,
    'दस': 10.0,
    'दहा': 10.0,
    'बीस': 20.0,
    'वीस': 20.0,
    'तीस': 30.0,
    'चालीस': 40.0,
    'चाळीस': 40.0,
    'पचास': 50.0,
    'पन्नास': 50.0,
    'डेढ़': 1.5,
    'दीड': 1.5,
    'ढाई': 2.5,
    'अडीच': 2.5,
  };

  static final _token = RegExp(
    r'₹|[\p{L}\p{M}.]+|\d[\d,]*(?:\.\d+)?',
    unicode: true,
  );

  static List<_Amount> _candidates(String lower) {
    final tokens = [
      for (final m in _token.allMatches(lower))
        (text: m.group(0)!, start: m.start, end: m.end),
    ];
    final found = <_Amount>[];

    for (var i = 0; i < tokens.length; i++) {
      final t = tokens[i].text;
      double? value = _numberWords[t];
      final numeric = RegExp(r'^\d[\d,]*(?:\.\d+)?$').hasMatch(t);
      if (numeric) value = double.tryParse(t.replaceAll(',', ''));
      // Bare multiplier: "सौ रुपये", "hundred rupees".
      final bareMultiplier = value == null ? _multipliers[t] : null;
      if (bareMultiplier != null && t != 'k' && t != 'शे') {
        value = bareMultiplier;
      } else if (value == null) {
        continue;
      }

      var end = tokens[i].end;
      var j = i + 1;
      if (bareMultiplier == null &&
          j < tokens.length &&
          _multipliers.containsKey(tokens[j].text)) {
        value *= _multipliers[tokens[j].text]!;
        end = tokens[j].end;
        j++;
      }

      final before = i > 0 && _currency.contains(tokens[i - 1].text);
      final after = j < tokens.length && _currency.contains(tokens[j].text);
      if (after) end = tokens[j].end;
      final start = before ? tokens[i - 1].start : tokens[i].start;

      found.add(
        _Amount(
          value: value,
          isInr: before || after,
          span: (start, end),
          numeric: numeric,
        ),
      );
      i = j - 1;
    }
    return found;
  }

  static _Amount? _amount(String lower) {
    final all = _candidates(lower).where((a) => a.value > 0).toList();
    if (all.isEmpty) return null;
    // Prefer an amount said with "rupees", then any digits, then the last
    // spoken number ("2 samosa 30" → 30).
    return all.where((a) => a.isInr).lastOrNull ??
        all.where((a) => a.numeric).lastOrNull ??
        all.last;
  }

  // --------------------------------------------------------------- payment

  static const Map<String, List<String>> _paymentWords = {
    'UPI': [
      'upi',
      'gpay',
      'google pay',
      'phonepe',
      'phone pe',
      'paytm',
      'bhim',
      'यूपीआई',
      'युपीआय',
      'यूपीआय',
      'जीपे',
      'फोनपे',
      'फोन पे',
      'पेटीएम',
    ],
    'Cash': ['cash', 'कैश', 'कॅश', 'नकद', 'नगद', 'रोख', 'रोकड', 'कॅशने'],
    'Card': [
      'card',
      'credit card',
      'debit card',
      'कार्ड',
      'क्रेडिट कार्ड',
      'डेबिट कार्ड',
      'कार्डने',
      'कार्ड से',
    ],
    'Bank Transfer': [
      'bank transfer',
      'neft',
      'imps',
      'rtgs',
      'net banking',
      'netbanking',
      'बैंक ट्रांसफर',
      'बँक ट्रान्सफर',
      'नेट बँकिंग',
      'नेट बैंकिंग',
    ],
  };

  // -------------------------------------------------------------- category

  static const Map<String, List<String>> _categoryWords = {
    'food': [
      'chai',
      'chaha',
      'tea',
      'coffee',
      'breakfast',
      'lunch',
      'dinner',
      'snacks',
      'samosa',
      'vada pav',
      'vadapav',
      'pizza',
      'burger',
      'biryani',
      'restaurant',
      'hotel',
      'milk',
      'grocery',
      'groceries',
      'vegetables',
      'sabzi',
      'bhaji',
      'kirana',
      'nashta',
      'khana',
      'food',
      'चहा',
      'चाय',
      'कॉफी',
      'नाश्ता',
      'नाष्टा',
      'जेवण',
      'खाना',
      'समोसा',
      'वडापाव',
      'वडा पाव',
      'पिज्जा',
      'बिर्याणी',
      'बिरयानी',
      'दूध',
      'भाजी',
      'सब्जी',
      'सब्ज़ी',
      'किराणा',
      'किराना',
      'मिठाई',
      'फळे',
      'फल',
      'हॉटेल',
      'होटल',
      'पाणीपुरी',
      'पानीपुरी',
    ],
    'transport': [
      'petrol',
      'diesel',
      'fuel',
      'auto',
      'rickshaw',
      'taxi',
      'cab',
      'bus',
      'train',
      'metro',
      'parking',
      'toll',
      'uber',
      'ola',
      'rapido',
      'पेट्रोल',
      'डिझेल',
      'डीजल',
      'ऑटो',
      'रिक्षा',
      'रिक्शा',
      'टॅक्सी',
      'टैक्सी',
      'बस',
      'ट्रेन',
      'मेट्रो',
      'पार्किंग',
      'टोल',
      'लोकल',
    ],
    'bills': [
      'bill',
      'electricity',
      'light bill',
      'recharge',
      'wifi',
      'internet',
      'broadband',
      'gas',
      'cylinder',
      'water bill',
      'rent',
      'emi',
      'बिल',
      'बिजली',
      'वीज',
      'लाईट बिल',
      'रिचार्ज',
      'वायफाय',
      'इंटरनेट',
      'गॅस',
      'गैस',
      'सिलेंडर',
      'भाडे',
      'भाड़ा',
      'किराया',
      'ईएमआई',
    ],
    'shopping': [
      'clothes',
      'shirt',
      'shoes',
      'shopping',
      'dress',
      'saree',
      'gift',
      'कपडे',
      'कपड़े',
      'शर्ट',
      'बूट',
      'जूते',
      'शॉपिंग',
      'साडी',
      'साड़ी',
      'गिफ्ट',
      'भेट',
    ],
    'health': [
      'medicine',
      'medicines',
      'doctor',
      'hospital',
      'clinic',
      'pharmacy',
      'medical',
      'tablets',
      'दवा',
      'दवाई',
      'औषध',
      'औषधे',
      'गोळ्या',
      'डॉक्टर',
      'दवाखाना',
      'हॉस्पिटल',
      'अस्पताल',
      'मेडिकल',
    ],
    'entertainment': [
      'movie',
      'cinema',
      'film',
      'netflix',
      'concert',
      'game',
      'सिनेमा',
      'चित्रपट',
      'फिल्म',
      'पिक्चर',
      'मूवी',
    ],
    'education': [
      'book',
      'books',
      'tuition',
      'school',
      'college',
      'course',
      'fees',
      'stationery',
      'पुस्तक',
      'पुस्तके',
      'किताब',
      'किताबें',
      'ट्यूशन',
      'शाळा',
      'स्कूल',
      'कॉलेज',
      'फी',
      'फीस',
      'क्लास',
      'वही',
    ],
    'travel': [
      'trip',
      'flight',
      'holiday',
      'vacation',
      'tour',
      'resort',
      'ट्रिप',
      'फ्लाइट',
      'सहल',
      'यात्रा',
      'प्रवास',
    ],
  };

  static String? _keywordCategory(
    String lower,
    bool Function(String) available,
  ) {
    for (final entry in _categoryWords.entries) {
      if (!available(entry.key)) continue;
      if (entry.value.any((w) => _containsWord(lower, w))) return entry.key;
    }
    return null;
  }

  static String? _match(String lower, Map<String, List<String>> table) {
    for (final entry in table.entries) {
      if (entry.value.any((w) => _containsWord(lower, w))) return entry.key;
    }
    return null;
  }

  /// Whole-word match that works for Devanagari (where `\b` doesn't). A
  /// Devanagari word may carry a case suffix ("चहाला", "बसने").
  static bool _containsWord(String haystack, String word) {
    final isLatin = RegExp(r'^[a-z0-9 .]+$').hasMatch(word);
    final pattern = isLatin
        ? '(?<![a-z0-9])${RegExp.escape(word)}(?![a-z0-9])'
        : '(?<![\\p{L}\\p{M}])${RegExp.escape(word)}'
              '(?:ला|ने|चा|ची|चे|साठी|के|को|से|में|मध्ये|वर)?(?![\\p{L}\\p{M}])';
    return RegExp(pattern, unicode: true).hasMatch(haystack);
  }

  // -------------------------------------------------------------- merchant

  /// A Latin-script word the merchant dictionary or the user's own history
  /// recognises ("Swiggy", "D-Mart", "Zomato").
  static String? _merchant(
    String text,
    List<ExpenseEntity> history,
    bool Function(String) available,
  ) {
    final words = RegExp(r'[A-Za-z][A-Za-z0-9&\-]*').allMatches(text).toList();
    for (var size = 2; size >= 1; size--) {
      for (var i = 0; i + size <= words.length; i++) {
        final phrase = text.substring(words[i].start, words[i + size - 1].end);
        final parts = phrase.toLowerCase().split(RegExp(r'\s+'));
        if (parts.any(_isGenericWord)) continue;
        final suggestion = CategorySuggester.suggest(
          merchant: phrase,
          history: history,
          isAvailable: available,
        );
        if (suggestion != null) return _titleCase(phrase);
      }
    }
    return null;
  }

  /// Removes payment phrases ("google pay") so their words aren't taken for
  /// a merchant name.
  static String _withoutPaymentWords(String text) {
    var out = text;
    for (final phrases in _paymentWords.values) {
      for (final p in phrases) {
        out = out.replaceAll(
          RegExp(
            '(?<![\\p{L}])${RegExp.escape(p)}(?![\\p{L}])',
            caseSensitive: false,
            unicode: true,
          ),
          ' ',
        );
      }
    }
    return out;
  }

  static bool _isGenericWord(String lower) =>
      _paymentWords.values.any((l) => l.contains(lower)) ||
      _currency.contains(lower) ||
      _categoryWords.values.any((l) => l.contains(lower)) ||
      _fillers.contains(lower);

  // ----------------------------------------------------------------- title

  static const _fillers = {
    'for',
    'on',
    'at',
    'to',
    'paid',
    'pay',
    'spent',
    'spend',
    'bought',
    'buy',
    'the',
    'a',
    'an',
    'of',
    'via',
    'by',
    'using',
    'with',
    'from',
    'and',
    'in',
    'add',
    'expense',
    'kharcha',
    'kharch',
    'ला',
    'साठी',
    'के',
    'लिए',
    'को',
    'का',
    'की',
    'में',
    'मध्ये',
    'से',
    'ने',
    'वर',
    'दिले',
    'दिए',
    'दिया',
    'भरले',
    'भरे',
    'खर्च',
    'खर्चा',
    'केले',
    'किया',
    'घेतले',
    'लिया',
    'आणि',
    'और',
    'चा',
    'ची',
    'चे',
  };

  static String? _title(String text, (int, int)? amountSpan, String? merchant) {
    var rest = text;
    if (amountSpan != null) {
      rest =
          '${text.substring(0, amountSpan.$1)} ${text.substring(amountSpan.$2)}';
    }
    final kept = <String>[];
    for (final m in _token.allMatches(_withoutPaymentWords(rest))) {
      final word = m.group(0)!;
      final lower = word.toLowerCase();
      if (RegExp(r'^\d').hasMatch(word)) continue;
      if (_fillers.contains(lower) || _currency.contains(lower)) continue;
      if (_multipliers.containsKey(lower)) continue;
      kept.add(word);
    }
    var title = kept.join(' ');
    title = title.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (title.isEmpty) return merchant;
    return title.length > 60
        ? title.substring(0, 60).trim()
        : _capitalize(title);
  }

  static String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  static String _titleCase(String s) => s
      .split(' ')
      .map((w) => w.length <= 2 || w.toUpperCase() == w ? w : _capitalize(w))
      .join(' ');
}

class _Amount {
  final double value;
  final bool isInr;
  final (int, int) span;
  final bool numeric;

  const _Amount({
    required this.value,
    required this.isInr,
    required this.span,
    required this.numeric,
  });
}
