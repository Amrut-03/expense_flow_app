import '../entities/captured_transaction.dart';

/// Extracts debit transactions from Indian bank / UPI SMS. Pure Dart, runs
/// entirely on-device.
///
/// Conservative by design: anything that is not clearly a completed debit
/// (credits, refunds, OTPs, promos, reminders, failed or future debits, ATM
/// cash withdrawals, messages from personal numbers) returns `null`, because
/// a missed payment is cheaper for the user than a fake one.
abstract final class TransactionSmsParser {
  static ParsedTransaction? parse({
    required String sender,
    required String body,
  }) {
    if (!isBankSender(sender)) return null;

    final text = body.replaceAll(RegExp(r'\s+'), ' ').trim();
    final lower = text.toLowerCase();

    if (_otp.hasMatch(lower) ||
        _promo.hasMatch(lower) ||
        _notCompleted.hasMatch(lower) ||
        _refund.hasMatch(lower) ||
        _cashWithdrawal.hasMatch(lower) ||
        !_debit.hasMatch(lower)) {
      return null;
    }

    final amount = _amount(text);
    if (amount == null || amount <= 0) return null;

    return ParsedTransaction(
      amount: amount,
      merchant: _merchant(text),
      paymentMethod: _paymentMethod(lower),
      reference: _reference(text),
    );
  }

  /// Commercial SMS senders in India look like `AD-HDFCBK`, `VM-ICICIT-S`
  /// or `HDFCBK`. Anything resembling a phone number is rejected so a
  /// person can't inject fake transactions by texting the user.
  static bool isBankSender(String sender) {
    final s = sender.trim();
    if (s.isEmpty) return false;
    final digits = s.replaceAll(RegExp(r'\D'), '').length;
    if (digits >= 7) return false;
    return RegExp(r'[A-Za-z]').hasMatch(s);
  }

  // --- classification -----------------------------------------------------

  static final _debit = RegExp(
    r'\b(debited|spent|sent|paid|withdrawn|purchase|charged|deducted|'
    r'txn of|transaction of|dr\b)',
  );

  static final _otp = RegExp(
    r'\b(otp|one[ -]time password|verification code|passcode)\b',
  );

  static final _promo = RegExp(
    r'(pre-?approved|apply now|limited period|congratulations|eligible for|'
    r'\boffer\b|\bwin\b|get (rs|inr|₹)|upto|up to (rs|inr|₹)|coupon|voucher)',
  );

  static final _notCompleted = RegExp(
    r'(will be debited|to be debited|is due|due on|due date|payment due|'
    r'scheduled|upcoming|\brequest(ed)?\b|failed|declined|unsuccessful|'
    r'could not be|has been blocked)',
  );

  static final _refund = RegExp(r'\b(refund(ed)?|reversal|reversed)\b');

  static final _cashWithdrawal = RegExp(
    r'(\batm\b|cash withdrawal|withdrawn at)',
  );

  // --- extraction ---------------------------------------------------------

  static final _currencyAmount = RegExp(
    r'(?:rs\.?|inr|₹)\s*([0-9][0-9,]*(?:\.[0-9]{1,2})?)',
    caseSensitive: false,
  );

  static final _debitedBy = RegExp(
    r'debited (?:by|for|with)\s*(?:rs\.?|inr|₹)?\s*([0-9][0-9,]*(?:\.[0-9]{1,2})?)',
    caseSensitive: false,
  );

  static double? _amount(String text) {
    for (final m in _currencyAmount.allMatches(text)) {
      // Skip balances and limits ("Avl Bal Rs 12,345").
      final before = text
          .substring((m.start - 18).clamp(0, m.start), m.start)
          .toLowerCase();
      if (RegExp(r'(bal|balance|limit|avl)[^a-z]*$').hasMatch(before)) {
        continue;
      }
      return _toDouble(m.group(1)!);
    }
    final m = _debitedBy.firstMatch(text);
    return m == null ? null : _toDouble(m.group(1)!);
  }

  static double? _toDouble(String raw) =>
      double.tryParse(raw.replaceAll(',', ''));

  static final _merchantPatterns = [
    // UPI/P2M/431234567890/ZOMATO LTD
    RegExp(
      r'upi/p2[am]/\d+/([^/\n]+?)(?:/|\s+not you|$)',
      caseSensitive: false,
    ),
    // "...; NETFLIX credited." (ICICI)
    RegExp(r';\s*([A-Za-z0-9&.\-\x27 ]+?)\s+credited', caseSensitive: false),
    // "at AMAZON on ..."
    RegExp(
      r'\bat\s+([A-Za-z0-9&*.\-\x27 ]+?)(?=\s+on\b|\s+ref|\s+via|\.|,|;|$)',
      caseSensitive: false,
    ),
    // "to SWIGGY on ...", "trf to RAPIDO Refno", "towards LIC"
    RegExp(
      r'\b(?:trf to|to|towards|for)\s+([A-Za-z0-9&*.\-\x27@ ]+?)'
      r'(?=\s+on\b|\s+ref|\s+upi|\s+via|\s+from|\.\s|,|;|$)',
      caseSensitive: false,
    ),
  ];

  static final _notAMerchant = RegExp(
    r'^(block|a/?c|ac\b|acct|account|your|you|xx|card|bank|upi|rs\b|inr|'
    r'dispute|sms|call|reissue|not\b|the\b|ending|no\.?\b|\d)',
    caseSensitive: false,
  );

  static String? _merchant(String text) {
    for (final pattern in _merchantPatterns) {
      for (final m in pattern.allMatches(text)) {
        final candidate = _cleanMerchant(m.group(1)!);
        if (candidate != null) return candidate;
      }
    }
    return null;
  }

  static String? _cleanMerchant(String raw) {
    var s = raw.trim();

    // VPA: "rapido@ybl" -> "rapido"; phone-number VPAs are people, not shops.
    final vpa = RegExp(r'^([A-Za-z0-9.\-_]+)@[A-Za-z]+$').firstMatch(s);
    if (vpa != null) {
      final local = vpa.group(1)!;
      if (RegExp(r'^\d+$').hasMatch(local)) return null;
      s = local.replaceAll(RegExp(r'[._\-]'), ' ');
    }

    s = s.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (s.length < 2 || s.length > 40 || _notAMerchant.hasMatch(s)) {
      return null;
    }
    return _titleCase(s);
  }

  static String _titleCase(String s) {
    if (s != s.toUpperCase() && s != s.toLowerCase()) return s;
    return s
        .toLowerCase()
        .split(' ')
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  static String _paymentMethod(String lower) {
    if (RegExp(r'\bupi\b|\bvpa\b|@[a-z]{2,}').hasMatch(lower)) return 'UPI';
    if (RegExp(r'\b(credit|debit)? ?card\b').hasMatch(lower)) return 'Card';
    if (RegExp(
      r'\b(neft|imps|rtgs|nach|ecs|a/?c|acct|account)\b',
    ).hasMatch(lower)) {
      return 'Bank Transfer';
    }
    return 'Other';
  }

  static final _referencePattern = RegExp(
    r'(?:ref(?:erence)?\.?\s*(?:no\.?|num(?:ber)?)?|refno|utr|rrn|upi(?:\s*ref)?)'
    r'[\s:.\-#]*(\d{6,})',
    caseSensitive: false,
  );

  static String? _reference(String text) =>
      _referencePattern.firstMatch(text)?.group(1);
}
