import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../../core/constants/category_label.dart';
import '../../../../core/logging/app_log_buffer.dart';
import '../domain/services/monthly_statement.dart';

/// Renders a [MonthlyStatement] as an A4 PDF.
///
/// Uses bundled Noto Sans (+ Devanagari fallback) so ₹ and Hindi/Marathi
/// titles render offline. Emoji are stripped since no emoji font is bundled.
class PdfStatementRenderer {
  PdfStatementRenderer({DateTime Function()? now}) : _now = now ?? DateTime.now;

  final DateTime Function() _now;
  pw.ThemeData? _theme;
  bool _unicode = false;

  static const _fontDir = 'assets/fonts';

  static final _accent = PdfColor.fromHex('#5B6CFF');
  static final _muted = PdfColor.fromHex('#6B7280');
  static final _line = PdfColor.fromHex('#E5E7EB');

  Future<Uint8List> render(MonthlyStatement s) async {
    final theme = await _loadTheme();
    final month = DateFormat('MMMM yyyy').format(s.month);
    final day = DateFormat('dd MMM');
    final generated = DateFormat('dd MMM yyyy, HH:mm').format(_now());

    final doc = pw.Document(
      title: 'ExpenseFlow statement · $month',
      author: 'ExpenseFlow',
      theme: theme,
    );

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (ctx) => ctx.pageNumber == 1
            ? pw.SizedBox()
            : pw.Text(
                'ExpenseFlow · $month',
                style: pw.TextStyle(fontSize: 8, color: _muted),
              ),
        footer: (ctx) => pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Generated on-device $generated',
              style: pw.TextStyle(fontSize: 7, color: _muted),
            ),
            pw.Text(
              'Page ${ctx.pageNumber} of ${ctx.pagesCount}',
              style: pw.TextStyle(fontSize: 7, color: _muted),
            ),
          ],
        ),
        build: (ctx) => [
          pw.Text(
            'Monthly statement',
            style: pw.TextStyle(fontSize: 10, color: _accent),
          ),
          pw.Text(
            month,
            style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 16),
          _summary(s),
          pw.SizedBox(height: 20),
          if (s.isEmpty)
            pw.Text(
              'No expenses recorded this month.',
              style: pw.TextStyle(color: _muted),
            )
          else ...[
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: _breakdown(
                    'By category',
                    s.byCategory,
                    s.total,
                    CategoryLabels.labelOf,
                  ),
                ),
                pw.SizedBox(width: 20),
                pw.Expanded(
                  child: _breakdown(
                    'By payment method',
                    s.byPaymentMethod,
                    s.total,
                    (k) => k,
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 20),
            _sectionTitle('Transactions (${s.expenses.length})'),
            pw.TableHelper.fromTextArray(
              headers: ['Date', 'Description', 'Category', 'Method', 'Amount'],
              data: [
                for (final e in s.expenses)
                  [
                    day.format(e.date),
                    _clean(
                      [
                        e.title,
                        e.merchant,
                      ].whereType<String>().where((t) => t.isNotEmpty).join(' · '),
                    ),
                    _clean(CategoryLabels.labelOf(e.categoryId)),
                    e.paymentMethod ?? '',
                    _money(e.amount) + (e.taxTag == null ? '' : '  [${e.taxTag}]'),
                  ],
              ],
              border: null,
              headerStyle: pw.TextStyle(
                fontSize: 8,
                fontWeight: pw.FontWeight.bold,
                color: _muted,
              ),
              cellStyle: const pw.TextStyle(fontSize: 8.5),
              headerDecoration: pw.BoxDecoration(
                border: pw.Border(bottom: pw.BorderSide(color: _line)),
              ),
              rowDecoration: pw.BoxDecoration(
                border: pw.Border(
                  bottom: pw.BorderSide(color: _line, width: 0.5),
                ),
              ),
              columnWidths: {
                0: const pw.FixedColumnWidth(44),
                1: const pw.FlexColumnWidth(3),
                2: const pw.FlexColumnWidth(1.4),
                3: const pw.FlexColumnWidth(1.2),
                4: const pw.FixedColumnWidth(80),
              },
              cellAlignments: {4: pw.Alignment.centerRight},
              headerAlignments: {4: pw.Alignment.centerRight},
              cellPadding: const pw.EdgeInsets.symmetric(
                vertical: 4,
                horizontal: 4,
              ),
            ),
            if (s.taxTaggedTotal > 0) ...[
              pw.SizedBox(height: 10),
              pw.Text(
                '[80C], [80D] … mark tax-deductible expenses '
                '(${_money(s.taxTaggedTotal)} this month).',
                style: pw.TextStyle(fontSize: 7.5, color: _muted),
              ),
            ],
          ],
        ],
      ),
    );

    return doc.save();
  }

  pw.Widget _summary(MonthlyStatement s) {
    final change = s.changeVsPreviousMonth;
    final largest = s.largest;
    final cells = <(String, String)>[
      ('Total spent', _money(s.total)),
      ('Transactions', '${s.expenses.length}'),
      ('Average per day', _money(s.averagePerDay(_now()))),
      (
        'vs last month',
        change == null
            ? '—'
            : '${change >= 0 ? '+' : '−'}${(change.abs() * 100).toStringAsFixed(0)}%',
      ),
    ];

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            color: PdfColor.fromHex('#F3F4FF'),
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Row(
            children: [
              for (final (label, value) in cells)
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        label,
                        style: pw.TextStyle(fontSize: 8, color: _muted),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        value,
                        style: pw.TextStyle(
                          fontSize: 13,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        if (largest != null) ...[
          pw.SizedBox(height: 6),
          pw.Text(
            'Largest expense: ${_money(largest.amount)} · '
            '${_clean(largest.title ?? largest.merchant ?? CategoryLabels.labelOf(largest.categoryId))}'
            ' on ${DateFormat('dd MMM').format(largest.date)}',
            style: pw.TextStyle(fontSize: 8, color: _muted),
          ),
        ],
      ],
    );
  }

  pw.Widget _sectionTitle(String text) => pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 6),
    child: pw.Text(
      text,
      style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
    ),
  );

  pw.Widget _breakdown(
    String title,
    List<StatementLine> lines,
    double total,
    String Function(String) label,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _sectionTitle(title),
        for (final line in lines)
          pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 6),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  children: [
                    pw.Expanded(
                      child: pw.Text(
                        _clean(label(line.key)),
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                    ),
                    pw.Text(
                      '${_money(line.total)}  '
                      '${(line.shareOf(total) * 100).toStringAsFixed(0)}%',
                      style: const pw.TextStyle(fontSize: 9),
                    ),
                  ],
                ),
                pw.SizedBox(height: 2),
                pw.Stack(
                  children: [
                    pw.Container(height: 3, color: _line),
                    pw.LayoutBuilder(
                      builder: (ctx, constraints) => pw.Container(
                        height: 3,
                        width:
                            (constraints?.maxWidth ?? 0) * line.shareOf(total),
                        color: _accent,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }

  String _money(double inr) {
    final formatted = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '',
      decimalDigits: 2,
    ).format(inr).trim();
    return _unicode ? '₹$formatted' : 'Rs. $formatted';
  }

  /// Strips emoji (no glyphs bundled) and, without the Unicode fonts, any
  /// character Helvetica can't draw.
  String _clean(String text) {
    final out = StringBuffer();
    for (final rune in text.runes) {
      final isEmoji =
          (rune >= 0x1F000 && rune <= 0x1FAFF) ||
          (rune >= 0x2600 && rune <= 0x27BF) ||
          rune == 0xFE0F ||
          rune == 0x200D;
      if (isEmoji) continue;
      if (!_unicode && rune > 0xFF) {
        out.write('?');
        continue;
      }
      out.writeCharCode(rune);
    }
    return out.toString().trim();
  }

  Future<pw.ThemeData> _loadTheme() async {
    final cached = _theme;
    if (cached != null) return cached;
    try {
      Future<pw.Font> font(String name) async =>
          pw.Font.ttf(await rootBundle.load('$_fontDir/$name'));
      final devanagari = await font('NotoSansDevanagari-Regular.ttf');
      final devanagariBold = await font('NotoSansDevanagari-Bold.ttf');
      _theme = pw.ThemeData.withFont(
        base: await font('NotoSans-Regular.ttf'),
        bold: await font('NotoSans-Bold.ttf'),
        fontFallback: [devanagari, devanagariBold],
      );
      _unicode = true;
    } catch (e, st) {
      // Missing assets shouldn't block the export; fall back to Latin-only.
      AppLogBuffer.instance.captureError('reports.fonts', e, st);
      _theme = pw.ThemeData.withFont(
        base: pw.Font.helvetica(),
        bold: pw.Font.helveticaBold(),
      );
      _unicode = false;
    }
    return _theme!;
  }
}
