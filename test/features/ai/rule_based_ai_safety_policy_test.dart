import 'package:expense_flow_app/features/ai/domain/entities/unsafe_topic.dart';
import 'package:expense_flow_app/features/ai/domain/services/safety/rule_based_ai_safety_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final policy = RuleBasedAiSafetyPolicy();

  UnsafeTopic? topicOf(String question) =>
      policy.assess(question).rejectedTopic;

  group('RuleBasedAiSafetyPolicy', () {
    test('allows ordinary spending questions', () {
      final verdict = policy.assess('How much did I spend on food this month?');

      expect(verdict.isAllowed, isTrue);
      expect(verdict.template, isNull);
    });

    test('rejects each unsafe topic with its template', () {
      final cases = {
        'Should I invest in mutual funds?': UnsafeTopic.investment,
        'How do I file my income tax?': UnsafeTopic.tax,
        'Is a home loan a good idea?': UnsafeTopic.loan,
        'What medicine should I take?': UnsafeTopic.medical,
      };

      cases.forEach((question, topic) {
        final verdict = policy.assess(question);
        expect(verdict.rejectedTopic, topic, reason: question);
        expect(
          verdict.template,
          RuleBasedAiSafetyPolicy.defaultTemplates[topic],
        );
      });
    });

    test('is case-insensitive', () {
      expect(topicOf('BITCOIN or STOCKS?'), UnsafeTopic.investment);
    });

    test('matches common suffixes of a keyword', () {
      expect(topicOf('Am I investing enough?'), UnsafeTopic.investment);
      expect(topicOf('Show my loans'), UnsafeTopic.loan);
    });

    // Regression: substring matching used to refuse these as advice.
    test('does not match keywords inside unrelated words', () {
      expect(topicOf('How much did I spend on taxi rides?'), isNull);
      expect(topicOf('List my premium subscriptions'), isNull);
      expect(topicOf('What did I spend on private classes?'), isNull);
      expect(topicOf('Total for Swiggy orders'), isNull);
    });

    test('honours custom keyword lists', () {
      final custom = RuleBasedAiSafetyPolicy(
        keywords: {
          UnsafeTopic.investment: ['gold'],
        },
      );

      expect(custom.assess('Buy gold?').rejectedTopic, UnsafeTopic.investment);
      expect(custom.assess('Should I invest?').isAllowed, isTrue);
    });
  });
}
