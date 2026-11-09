import 'package:intl/intl.dart';

import '../../../../core/constants/category_label.dart';
import '../../../expense/domain/entities/expense_entity.dart';
import '../../../tax/domain/usecases/get_tax_summary_usecase.dart';

/// Builds spreadsheet-friendly CSV (RFC 4180) from expenses.
///
/// Output starts with a UTF-8 BOM so Excel shows ₹ and Hindi/Marathi text
/// correctly, uses CRLF line endings, and neutralises cells that a
/// spreadsheet would otherwise evaluate as formulas (CSV injection).
abstract final class ExpenseCsvBuilder {
  static const bom = '﻿';

  static const headers = [
    'Date',
    'Title',
    'Merchant',
    'Category',
    'Amount (INR)',
    'Original amount',
    'Currency',
    'Payment method',
    'Tax section',
    'Note',
  ];

  static final _date = DateFormat('yyyy-MM-dd');

  /// Non-deleted [expenses], oldest first.
  static String build(Iterable<ExpenseEntity> expenses) {
    final rows = expenses.where((e) => !e.isDeleted).toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    return _join([
      headers,
      for (final e in rows)
        [
          _date.format(e.date),
          _text(e.title),
          _text(e.merchant),
          _text(CategoryLabels.labelOf(e.categoryId)),
          _amount(e.amount),
          e.originalAmount == null ? '' : _amount(e.originalAmount!),
          e.currency,
          _text(e.paymentMethod),
          e.taxTag ?? '',
          _text(e.note),
        ],
    ]);
  }

  /// One row per tagged expense plus a per-section total, for filing.
  static String buildTaxSummary(TaxSummary summary) {
    return _join([
      ['Financial year', summary.year.label],
      const [],
      ['Section', 'Date', 'Title', 'Merchant', 'Amount (INR)'],
      for (final section in summary.sections) ...[
        for (final e in section.expenses)
          [
            section.section.code,
            _date.format(e.date),
            _text(e.title),
            _text(e.merchant),
            _amount(e.amount),
          ],
        [
          '${section.section.code} total',
          '',
          '',
          section.section.cap == null
              ? 'No fixed limit'
              : 'Limit ${_amount(section.section.cap!)}',
          _amount(section.total),
        ],
      ],
      const [],
      ['Estimated deductible', '', '', '', _amount(summary.totalClaimable)],
      const ['Old tax regime only. Guidance, not tax advice.'],
    ]);
  }

  static String _join(List<List<String>> rows) {
    final body = rows.map((r) => r.map(_escape).join(',')).join('\r\n');
    return '$bom$body\r\n';
  }

  static String _amount(double v) => v.toStringAsFixed(2);

  /// User-entered text: a leading `= + - @` (or tab/CR) would make Excel or
  /// Sheets treat the cell as a formula, so prefix it with an apostrophe.
  static String _text(String? value) {
    if (value == null || value.isEmpty) return '';
    const triggers = ['=', '+', '-', '@', '\t', '\r'];
    return triggers.any(value.startsWith) ? "'$value" : value;
  }

  static String _escape(String cell) {
    final needsQuotes =
        cell.contains(',') ||
        cell.contains('"') ||
        cell.contains('\n') ||
        cell.contains('\r');
    if (!needsQuotes) return cell;
    return '"${cell.replaceAll('"', '""')}"';
  }
}
