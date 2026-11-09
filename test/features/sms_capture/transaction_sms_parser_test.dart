import 'package:expense_flow_app/features/sms_capture/domain/entities/captured_transaction.dart';
import 'package:expense_flow_app/features/sms_capture/domain/services/transaction_sms_parser.dart';
import 'package:flutter_test/flutter_test.dart';

ParsedTransaction? parse(String body, {String sender = 'AD-HDFCBK'}) =>
    TransactionSmsParser.parse(sender: sender, body: body);

void main() {
  group('debits that should be captured', () {
    test('HDFC UPI "Sent" multi-line format', () {
      final t = parse(
        'Sent Rs.250.00\nFrom HDFC Bank A/C *1234\nTo SWIGGY\nOn 05/11/26\n'
        'Ref 431234567890\nNot You?\nCall 18002586161/SMS BLOCK UPI to 7308080808',
      )!;
      expect(t.amount, 250);
      expect(t.merchant, 'Swiggy');
      expect(t.paymentMethod, 'UPI');
      expect(t.reference, '431234567890');
    });

    test('HDFC card "Spent ... At MERCHANT On"', () {
      final t = parse(
        'Spent Rs.1,499.00 On HDFC Bank Card 1234 At AMAZON On '
        '2026-11-05:14:22:01.Not You? To Block+Reissue Call 18002323232/SMS '
        'BLOCK CC 1234 to 7308080808',
      )!;
      expect(t.amount, 1499);
      expect(t.merchant, 'Amazon');
      expect(t.paymentMethod, 'Card');
    });

    test('ICICI "debited for ...; MERCHANT credited"', () {
      final t = parse(
        'ICICI Bank Acct XX123 debited for Rs 349.00 on 05-Nov-26; NETFLIX '
        'credited. UPI:431234567890. Call 18002662 for dispute. SMS BLOCK 123 '
        'to 9215676766.',
        sender: 'VM-ICICIT-S',
      )!;
      expect(t.amount, 349);
      expect(t.merchant, 'Netflix');
      expect(t.paymentMethod, 'UPI');
      expect(t.reference, '431234567890');
    });

    test('SBI "debited by" without a currency symbol', () {
      final t = parse(
        'Dear UPI user A/C X1234 debited by 120.0 on date 05Nov26 trf to RAPIDO '
        'Refno 431234567890. If not u? call 1800111109. -SBI',
        sender: 'JD-SBIUPI-S',
      )!;
      expect(t.amount, 120);
      expect(t.merchant, 'Rapido');
      expect(t.reference, '431234567890');
    });

    test('Axis UPI/P2M reference format', () {
      final t = parse(
        'INR 560.00 debited\nA/c no. XX1234\n05-11-26, 13:45:10\n'
        'UPI/P2M/431234567890/ZOMATO LTD\nNot you? SMS BLOCKUPI Cust ID to '
        '919951860002\nAxis Bank',
        sender: 'AX-AXISBK',
      )!;
      expect(t.amount, 560);
      expect(t.merchant, 'Zomato Ltd');
      expect(t.paymentMethod, 'UPI');
    });

    test('Kotak payment to a VPA uses the VPA name', () {
      final t = parse(
        'Sent Rs.80.00 from Kotak Bank AC X1234 to rapido@ybl on 05-11-26.'
        'UPI Ref 431234567890. Not you, https://kotak.com/KBANKT/Fraud',
        sender: 'BZ-KOTAKB',
      )!;
      expect(t.amount, 80);
      expect(t.merchant, 'Rapido');
    });

    test('payment to a phone-number VPA has no merchant', () {
      final t = parse(
        'Sent Rs.500.00 from Kotak Bank AC X1234 to 9876543210@ybl on '
        '05-11-26.UPI Ref 431234567890.',
        sender: 'BZ-KOTAKB',
      )!;
      expect(t.amount, 500);
      expect(t.merchant, isNull);
    });

    test('Indian digit grouping and ignores the balance amount', () {
      final t = parse(
        'Rs 1,23,456.50 debited from A/c XX12 via NEFT on 05-11-26. '
        'Avl Bal Rs 2,00,000.00',
      )!;
      expect(t.amount, 123456.5);
      expect(t.paymentMethod, 'Bank Transfer');
    });

    test('balance mentioned first is skipped', () {
      final t = parse(
        'Avl Bal Rs 9,000.00. Rs 450.00 debited from A/c XX12 at DMART on 05-11.',
      )!;
      expect(t.amount, 450);
      expect(t.merchant, 'Dmart');
    });
  });

  group('messages that must be ignored', () {
    final ignored = {
      'credit':
          'Rs.5000.00 credited to A/c XX1234 on 05-11-26 by UPI ref '
          '431234567890. -SBI',
      'money received': 'Received Rs.500 from Rahul via UPI. Ref 4312345678.',
      'OTP':
          '123456 is your OTP for txn of Rs 2,000.00 at AMAZON on HDFC Bank '
          'card ending 1234. Valid for 10 mins. Do not share.',
      'promo': 'Get Rs.500 cashback on your next recharge! Use code SAVE500.',
      'pre-approved loan':
          'Congratulations! You are eligible for a '
          'pre-approved loan of Rs 5,00,000. Apply now.',
      'balance alert': 'Avl Bal in A/c XX1234 is Rs 12,345.67 as on 05-11-26.',
      'ATM withdrawal': 'Rs.2000 withdrawn at ATM 1234 from A/c XX12 on 05-11.',
      'failed':
          'Your transaction of Rs 500 at FLIPKART has failed. Amount '
          'will be refunded.',
      'refund':
          'Refund of Rs 499.00 from AMAZON has been credited to your card.',
      'future debit': 'Rs 499 will be debited on 10-Nov for NETFLIX mandate.',
      'bill reminder':
          'Your HDFC credit card bill of Rs 5,000 is due on 15-Nov.',
      'collect request':
          'Merchant XYZ has requested Rs 200 via UPI. Approve '
          'in your app.',
    };

    ignored.forEach((name, body) {
      test(name, () => expect(parse(body), isNull));
    });

    test('debit SMS from a personal number (spoofing)', () {
      expect(
        parse('Sent Rs.250.00 to SWIGGY on 05/11/26', sender: '+919876543210'),
        isNull,
      );
    });
  });

  group('isBankSender', () {
    test('accepts DLT headers and plain bank codes', () {
      expect(TransactionSmsParser.isBankSender('AD-HDFCBK'), isTrue);
      expect(TransactionSmsParser.isBankSender('VM-ICICIT-S'), isTrue);
      expect(TransactionSmsParser.isBankSender('HDFCBK'), isTrue);
    });

    test('rejects phone numbers and empty senders', () {
      expect(TransactionSmsParser.isBankSender('+919876543210'), isFalse);
      expect(TransactionSmsParser.isBankSender('9876543210'), isFalse);
      expect(TransactionSmsParser.isBankSender(''), isFalse);
    });
  });
}
