import '../../entities/safety_verdict.dart';
import '../../entities/unsafe_topic.dart';
import 'ai_safety_policy.dart';

/// Rule-based [AiSafetyPolicy] that rejects investment, tax, loan, and
/// medical advice.
///
/// Matching is simple, case-insensitive keyword containment. A hit immediately
/// returns a rejected verdict carrying a canned template response; questions
/// that match nothing are allowed to proceed.
class RuleBasedAiSafetyPolicy implements AiSafetyPolicy {
  RuleBasedAiSafetyPolicy({Map<UnsafeTopic, List<String>>? keywords})
    : _keywords = keywords ?? _defaultKeywords;

  final Map<UnsafeTopic, List<String>> _keywords;

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
        'consult a tax professional.',
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
      for (final keyword in _keywords[topic] ?? const <String>[]) {
        if (normalized.contains(keyword)) {
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
