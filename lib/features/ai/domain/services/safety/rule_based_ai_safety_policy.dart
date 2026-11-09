import '../../entities/safety_verdict.dart';
import '../../entities/unsafe_topic.dart';
import 'ai_safety_policy.dart';

/// Rule-based [AiSafetyPolicy] that rejects investment, tax, loan, and
/// medical advice.
///
/// Matching is case-insensitive and whole-word, with common English suffixes
/// allowed (`loan` matches `loans`, `invest` matches `investing`) so everyday
/// spending words such as `taxi` or `premium` are not mistaken for `tax` or
/// `emi`. A hit immediately returns a rejected verdict carrying a canned
/// template response; questions that match nothing are allowed to proceed.
class RuleBasedAiSafetyPolicy implements AiSafetyPolicy {
  RuleBasedAiSafetyPolicy({Map<UnsafeTopic, List<String>>? keywords})
    : _patterns = {
        for (final entry in (keywords ?? _defaultKeywords).entries)
          entry.key: [for (final keyword in entry.value) _wordPattern(keyword)],
      };

  final Map<UnsafeTopic, List<RegExp>> _patterns;

  static RegExp _wordPattern(String keyword) {
    return RegExp(
      '\\b${RegExp.escape(keyword.toLowerCase())}(?:s|es|ed|ing|ments?)?\\b',
    );
  }

  static final Map<UnsafeTopic, List<String>> _defaultKeywords = {
    UnsafeTopic.investment: const [
      'invest',
      'investment',
      'stock',
      'stocks',
      'stock market',
      'shares',
      'equities',
      'mutual fund',
      'crypto',
      'bitcoin',
      'dividend',
      'portfolio',
      'trading',
      'return on investment',
      'roi',
    ],
    UnsafeTopic.tax: const [
      'tax',
      'taxes',
      'taxation',
      'taxable',
      'tax return',
      'income tax',
      'gst',
      'vat',
      'itr',
      'deduction',
      'tax credit',
      'tax filing',
    ],
    UnsafeTopic.loan: const [
      'loan',
      'mortgage',
      'emi',
      'borrow',
      'borrowing',
      'interest rate',
      'credit line',
      'lending',
      'lender',
    ],
    UnsafeTopic.medical: const [
      'medical',
      'medicine',
      'medication',
      'prescription',
      'disease',
      'illness',
      'symptom',
      'treatment',
      'doctor',
      'therapy',
      'diagnosis',
      'dosage',
      'health issue',
    ],
  };

  /// Canned responses returned for each [UnsafeTopic].
  static const Map<UnsafeTopic, String> defaultTemplates = {
    UnsafeTopic.investment:
        'I can\'t give investment advice. I can help you '
        'track and categorise your spending instead.',
    UnsafeTopic.tax:
        'I can\'t give tax advice. For tax filing, please '
        'consult a tax professional. Your tagged deductions are summarised '
        'under Settings → Tax deductions.',
    UnsafeTopic.loan:
        'I can\'t give loan or borrowing advice. Please consult '
        'a financial professional.',
    UnsafeTopic.medical:
        'I can\'t give medical advice. For health concerns, '
        'please consult a doctor.',
  };

  @override
  SafetyVerdict assess(String question) {
    final normalized = question.toLowerCase();

    for (final topic in UnsafeTopic.values) {
      for (final pattern in _patterns[topic] ?? const <RegExp>[]) {
        if (pattern.hasMatch(normalized)) {
          return SafetyVerdict.rejected(
            topic: topic,
            template: defaultTemplates[topic]!,
          );
        }
      }
    }

    return const SafetyVerdict.allowed();
  }
}
