import '../entities/receipt_draft.dart';

/// Turns OCR rows from an Indian bill/receipt into a [ReceiptDraft].
///
/// Pure and rule-based: totals by keyword priority (grand total › net
/// payable › total), GST from CGST/SGST/IGST rows, day-first dates, line
/// items as "text … amount" rows above the total, merchant from the header.
abstract final class ReceiptParser {
  static const maxItems = 40;

  /// Higher wins. "subtotal" etc. are excluded separately.
  static const _totalKeywords = <String, int>{
    'grand total': 5,
    'net payable': 5,
    'amount payable': 5,
    'total payable': 5,
    'net amount': 4,
    'bill amount': 4,
    'total amount': 4,
    'amount due': 4,
    'balance due': 4,
    'to pay': 4,
    'net total': 4,
    'total': 3,
    'amount': 1,
  };

  static const _notTotal = [
    'subtotal',
    'sub total',
    'sub-total',
    'total qty',
    'total quantity',
    'total items',
    'total item',
    'no of items',
    'total savings',
    'you saved',
    'total discount',
    'total tax',
    'taxable',
    'total gst',
  ];

  static const _nonItemWords = [
    'total',
    'tax',
    'gst',
    'cgst',
    'sgst',
    'igst',
    'cess',
    'vat',
    'discount',
    'round',
    'change',
    'cash',
    'card',
    'upi',
    'paid',
    'tender',
    'balance',
    'amount',
    'savings',
    'saved',
    'qty',
    'invoice',
    'bill no',
    'table',
    'gstin',
    'fssai',
    'phone',
    'mobile',
    'tel',
    'date',
    'time',
  ];

  static const _headerNoise = [
    'tax invoice',
    'invoice',
    'receipt',
    'bill of supply',
    'cash memo',
    'gstin',
    'gst no',
    'fssai',
    'phone',
    'ph:',
    'ph.',
    'mob',
    'tel',
    'www',
    'http',
    '@',
    'date',
    'bill no',
    'order',
    'welcome',
    'thank',
    'original',
    'duplicate',
    'copy',
  ];

  static final _amountPattern = RegExp(
    r'(?:₹|rs\.?|inr)?\s*(\d{1,3}(?:,\d{2,3})+|\d+)(?:\.(\d{1,2}))?(?!\d)',
    caseSensitive: false,
  );

  static ReceiptDraft parse(List<String> rawLines, {required DateTime now}) {
    final lines = [
      for (final l in rawLines)
        if (l.trim().isNotEmpty) l.replaceAll(RegExp(r'\s+'), ' ').trim(),
    ];
    if (lines.isEmpty) return const ReceiptDraft();

    final totalIndex = _findTotal(lines);
    final endOfItems = totalIndex?.$1 ?? lines.length;
    final items = _items(lines, endOfItems, totalIndex?.$2);
    final total = totalIndex?.$2 ?? _fallbackTotal(lines, items);

    return ReceiptDraft(
      total: total,
      merchant: _merchant(lines),
      date: _date(lines, now),
      tax: _tax(lines),
      items: items,
      paymentMethod: _payment(lines),
      lines: lines,
    );
  }

  /// Amounts on a line, ignoring things that look like times, phone numbers,
  /// percentages and quantities ("2 x").
  static List<double> amountsIn(String line) {
    final cleaned = line
        .replaceAll(RegExp(r'\b\d{1,2}:\d{2}(:\d{2})?\b'), ' ')
        .replaceAll(RegExp(r'\b\d{1,2}[/.-]\d{1,2}[/.-]\d{2,4}\b'), ' ')
        .replaceAll(RegExp(r'\d+(\.\d+)?\s*%'), ' ')
        .replaceAll(RegExp(r'\b\d{10,}\b'), ' ');
    return [
      for (final m in _amountPattern.allMatches(cleaned))
        ?double.tryParse(
          '${m.group(1)!.replaceAll(',', '')}.${m.group(2) ?? '0'}',
        ),
    ];
  }

  /// (line index, amount) of the best total, or null.
  static (int, double)? _findTotal(List<String> lines) {
    (int, double, int)? best;
    for (var i = 0; i < lines.length; i++) {
      final lower = lines[i].toLowerCase();
      if (_notTotal.any(lower.contains)) continue;
      var priority = 0;
      for (final e in _totalKeywords.entries) {
        if (e.value > priority && lower.contains(e.key)) priority = e.value;
      }
      if (priority == 0) continue;

      var amounts = amountsIn(lines[i]);
      // Total printed on the next row.
      if (amounts.isEmpty && i + 1 < lines.length) {
        amounts = amountsIn(lines[i + 1]);
      }
      if (amounts.isEmpty) continue;
      final amount = amounts.last;
      if (amount <= 0) continue;
      // Same priority later in the bill wins (grand total comes last).
      if (best == null || priority >= best.$3) best = (i, amount, priority);
    }
    return best == null ? null : (best.$1, best.$2);
  }

  /// No total line: the items' sum if there are items, else the largest
  /// money-shaped amount (₹/Rs prefix or two decimals).
  static double? _fallbackTotal(
    List<String> lines,
    List<ReceiptLineItem> items,
  ) {
    if (items.isNotEmpty) {
      return double.parse(
        items.fold<double>(0, (s, i) => s + i.amount).toStringAsFixed(2),
      );
    }
    final money = RegExp(
      r'(?:(?:₹|rs\.?|inr)\s*(\d{1,3}(?:,\d{2,3})+|\d+)(?:\.(\d{1,2}))?)|'
      r'(?:(\d{1,3}(?:,\d{2,3})+|\d+)\.(\d{2})(?!\d))',
      caseSensitive: false,
    );
    double? max;
    for (final l in lines) {
      for (final m in money.allMatches(l)) {
        final whole = (m.group(1) ?? m.group(3))!.replaceAll(',', '');
        final v = double.tryParse('$whole.${m.group(2) ?? m.group(4) ?? '0'}');
        if (v != null && (max == null || v > max)) max = v;
      }
    }
    return max;
  }

  static String? _merchant(List<String> lines) {
    for (final line in lines.take(6)) {
      final lower = line.toLowerCase();
      if (_headerNoise.any(lower.contains)) continue;
      final letters = RegExp(r'\p{L}', unicode: true).allMatches(line).length;
      final digits = RegExp(r'\d').allMatches(line).length;
      if (letters < 3 || digits > letters / 3) continue;
      // Address lines usually have commas and numbers.
      if (RegExp(r',.*\d|\d.*,').hasMatch(line)) continue;
      return _titleCase(
        line
            .replaceAll(RegExp(r'[^\p{L}\p{N}&\x27 .-]', unicode: true), '')
            .trim(),
      );
    }
    return null;
  }

  static String _titleCase(String s) {
    final isShouty = s == s.toUpperCase();
    if (!isShouty) return s;
    return s
        .toLowerCase()
        .split(' ')
        .map((w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1))
        .join(' ');
  }

  static const _months = {
    'jan': 1,
    'feb': 2,
    'mar': 3,
    'apr': 4,
    'may': 5,
    'jun': 6,
    'jul': 7,
    'aug': 8,
    'sep': 9,
    'oct': 10,
    'nov': 11,
    'dec': 12,
  };

  static DateTime? _date(List<String> lines, DateTime now) {
    final numeric = RegExp(r'\b(\d{1,2})[/.-](\d{1,2})[/.-](\d{2,4})\b');
    final iso = RegExp(r'\b(20\d{2})-(\d{1,2})-(\d{1,2})\b');
    final named = RegExp(
      r'\b(\d{1,2})[\s-]*(jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)[a-z]*[\s,-]*(\d{2,4})\b',
      caseSensitive: false,
    );
    for (final line in lines) {
      DateTime? candidate;
      if (iso.firstMatch(line) case final m?) {
        candidate = _safeDate(
          int.parse(m.group(1)!),
          int.parse(m.group(2)!),
          int.parse(m.group(3)!),
        );
      } else if (numeric.firstMatch(line) case final m?) {
        // India: day first.
        candidate = _safeDate(
          _year(int.parse(m.group(3)!)),
          int.parse(m.group(2)!),
          int.parse(m.group(1)!),
        );
      } else if (named.firstMatch(line) case final m?) {
        candidate = _safeDate(
          _year(int.parse(m.group(3)!)),
          _months[m.group(2)!.toLowerCase()]!,
          int.parse(m.group(1)!),
        );
      }
      if (candidate == null) continue;
      final tomorrow = DateTime(now.year, now.month, now.day + 1);
      final yearAgo = DateTime(now.year - 1, now.month, now.day);
      if (candidate.isBefore(tomorrow) && !candidate.isBefore(yearAgo)) {
        return candidate;
      }
    }
    return null;
  }

  static int _year(int y) => y < 100 ? 2000 + y : y;

  static DateTime? _safeDate(int y, int m, int d) {
    if (m < 1 || m > 12 || d < 1 || d > 31) return null;
    final date = DateTime(y, m, d);
    return date.month == m ? date : null;
  }

  static double? _tax(List<String> lines) {
    var sum = 0.0;
    var found = false;
    for (final line in lines) {
      final lower = line.toLowerCase();
      if (lower.contains('gstin')) continue;
      if (!RegExp(r'\b(cgst|sgst|utgst|igst)\b').hasMatch(lower)) continue;
      final amounts = amountsIn(line);
      if (amounts.isEmpty) continue;
      sum += amounts.last;
      found = true;
    }
    return found && sum > 0 ? double.parse(sum.toStringAsFixed(2)) : null;
  }

  static List<ReceiptLineItem> _items(
    List<String> lines,
    int end,
    double? total,
  ) {
    final items = <ReceiptLineItem>[];
    for (var i = 0; i < end && items.length < maxItems; i++) {
      final line = lines[i];
      final lower = line.toLowerCase();
      if (_nonItemWords.any(
        (w) =>
            RegExp('(^|[^a-z])${RegExp.escape(w)}([^a-z]|\$)').hasMatch(lower),
      )) {
        continue;
      }
      final amountMatch = RegExp(
        r'(\d{1,3}(?:,\d{2,3})+|\d+)\.(\d{2})\s*$',
      ).firstMatch(line);
      if (amountMatch == null) continue;
      final amount = double.parse(
        '${amountMatch.group(1)!.replaceAll(',', '')}.${amountMatch.group(2)}',
      );
      if (amount <= 0 || (total != null && amount > total)) continue;
      // Strip qty/rate columns: keep the leading text.
      final name = line
          .substring(0, amountMatch.start)
          .replaceAll(RegExp(r'(\s+\d+(\.\d+)?)+\s*$'), '')
          .replaceAll(RegExp(r'^\d+[.)]?\s+'), '')
          .replaceAll(RegExp(r'\s+[x×@]\s*$', caseSensitive: false), '')
          .trim();
      if (RegExp(r'\p{L}', unicode: true).allMatches(name).length < 2) continue;
      items.add(ReceiptLineItem(_titleCase(name), amount));
    }
    return items;
  }

  static String? _payment(List<String> lines) {
    final text = lines.join(' ').toLowerCase();
    if (RegExp(
      r'\b(upi|gpay|google pay|phonepe|paytm|bhim)\b',
    ).hasMatch(text)) {
      return 'UPI';
    }
    if (RegExp(
      r'\b(card|visa|mastercard|rupay|amex|debit|credit)\b',
    ).hasMatch(text)) {
      return 'Card';
    }
    if (RegExp(r'\bcash\b').hasMatch(text)) return 'Cash';
    return null;
  }
}
