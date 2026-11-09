import 'package:expense_flow_app/features/voice_entry/domain/services/voice_expense_parser.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/expense_factory.dart';

void main() {
  group('VoiceExpenseParser', () {
    test('Marathi: चहा 20 रुपये', () {
      final d = VoiceExpenseParser.parse('चहा 20 रुपये');
      expect(d.amount, 20);
      expect(d.amountIsInr, isTrue);
      expect(d.categoryId, 'food');
      expect(d.title, 'चहा');
    });

    test('Hindi with Devanagari digits and payment method', () {
      final d = VoiceExpenseParser.parse('पेट्रोल ५०० रुपये नकद');
      expect(d.amount, 500);
      expect(d.categoryId, 'transport');
      expect(d.paymentMethod, 'Cash');
      expect(d.title, 'पेट्रोल');
    });

    test('multiplier words', () {
      expect(VoiceExpenseParser.parse('किराया 12 हजार').amount, 12000);
      expect(VoiceExpenseParser.parse('कपडे दीड हजार रुपये').amount, 1500);
      expect(VoiceExpenseParser.parse('दवाई सौ रुपये').amount, 100);
      expect(VoiceExpenseParser.parse('shoes 2 thousand card').amount, 2000);
    });

    test('prefers the number said with rupees, else the last number', () {
      expect(VoiceExpenseParser.parse('2 samosa 30 rupees').amount, 30);
      expect(VoiceExpenseParser.parse('₹45 for 3 vada pav').amount, 45);
      expect(VoiceExpenseParser.parse('2 samosa 30').amount, 30);
      expect(VoiceExpenseParser.parse('1,250.50 groceries').amount, 1250.5);
    });

    test('English with merchant and UPI', () {
      final d = VoiceExpenseParser.parse('paid 250 to swiggy on google pay');
      expect(d.amount, 250);
      expect(d.amountIsInr, isFalse);
      expect(d.merchant, 'Swiggy');
      expect(d.categoryId, 'food');
      expect(d.paymentMethod, 'UPI');
      expect(d.title, 'Swiggy');
    });

    test('Marathi suffixes and mixed script', () {
      final d = VoiceExpenseParser.parse('रिक्षाला 60 रुपये दिले फोनपे');
      expect(d.amount, 60);
      expect(d.categoryId, 'transport');
      expect(d.paymentMethod, 'UPI');
      expect(d.title, 'रिक्षाला');
    });

    test('learns merchants from history', () {
      final history = [
        expenseOf(
          amount: 80,
          date: DateTime(2026, 11, 1),
          merchant: 'Sharma Dairy',
          categoryId: 'food',
        ),
      ];
      final d = VoiceExpenseParser.parse(
        'Sharma Dairy 64 rupees',
        history: history,
      );
      expect(d.merchant, 'Sharma Dairy');
      expect(d.categoryId, 'food');
    });

    test('respects unavailable categories', () {
      final d = VoiceExpenseParser.parse(
        'movie 300',
        isAvailable: (id) => id != 'entertainment',
      );
      expect(d.categoryId, isNull);
      expect(d.amount, 300);
    });

    test('does not misread words inside other words', () {
      // "bus" inside "business", "बस" inside "बसवले".
      expect(VoiceExpenseParser.parse('business lunch 900').categoryId, 'food');
      expect(VoiceExpenseParser.parse('बसवले 50').categoryId, isNull);
    });

    test('nothing to parse', () {
      expect(VoiceExpenseParser.parse('   ').isEmpty, isTrue);
      final d = VoiceExpenseParser.parse('hello there');
      expect(d.amount, isNull);
    });

    test('numbersIn lists every amount for model validation', () {
      expect(VoiceExpenseParser.numbersIn('2 samosa ३० रुपये, 1 हजार'), [
        2,
        30,
        1000,
      ]);
    });
  });
}
