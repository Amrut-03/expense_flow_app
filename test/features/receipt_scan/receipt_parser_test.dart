import 'package:expense_flow_app/features/receipt_scan/domain/entities/receipt_draft.dart';
import 'package:expense_flow_app/features/receipt_scan/domain/services/receipt_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 11, 9, 20);

  test('restaurant bill with GST', () {
    final d = ReceiptParser.parse([
      'MEGHANA FOODS',
      'No 124, Residency Road, Bengaluru 560025',
      'GSTIN: 29AABCM1234F1Z5',
      'Ph: 9876543210',
      'TAX INVOICE',
      'Bill No: 4521   Date: 07/11/2026  21:14',
      'Item Qty Rate Amount',
      'Chicken Biryani 2 320.00 640.00',
      'Paneer Tikka 1 280.00 280.00',
      'Fresh Lime Soda 2 60.00 120.00',
      'Sub Total 1040.00',
      'CGST @2.5% 26.00',
      'SGST @2.5% 26.00',
      'Round Off 0.00',
      'Grand Total ₹ 1,092.00',
      'Paid via UPI',
      'Thank you! Visit again',
    ], now: now);
    expect(d.merchant, 'Meghana Foods');
    expect(d.total, 1092);
    expect(d.tax, 52);
    expect(d.date, DateTime(2026, 11, 7));
    expect(d.paymentMethod, 'UPI');
    expect(d.items, const [
      ReceiptLineItem('Chicken Biryani', 640),
      ReceiptLineItem('Paneer Tikka', 280),
      ReceiptLineItem('Fresh Lime Soda', 120),
    ]);
  });

  test('supermarket: total on the next row, ignores qty/savings totals', () {
    final d = ReceiptParser.parse([
      'Welcome to',
      'DMart',
      'Avenue Supermarts Ltd',
      '05-Nov-26 18:02',
      'Tata Salt 1kg 28.00',
      'Amul Butter 500g 275.00',
      'Total Qty: 2',
      'Total Savings Rs 12.00',
      'NET PAYABLE',
      'Rs. 303.00',
      'CARD **** 4421',
    ], now: now);
    expect(d.merchant, 'DMart');
    expect(d.total, 303);
    expect(d.date, DateTime(2026, 11, 5));
    expect(d.paymentMethod, 'Card');
    expect(d.items.map((i) => i.name), ['Tata Salt 1kg', 'Amul Butter 500g']);
  });

  test('no total line: sum of items, else largest money-shaped amount', () {
    final d = ReceiptParser.parse([
      'Sharma Medicals',
      'Paracetamol 650 strip 32.50',
      'Vitamin C 120.00',
      'Thank you',
    ], now: now);
    expect(d.total, 152.5);
    expect(d.items.first.name, 'Paracetamol 650 strip');
    expect(d.merchant, 'Sharma Medicals');

    final noItems = ReceiptParser.parse([
      'Auto fare',
      'Distance 650 m',
      'Fare Rs 45',
    ], now: now);
    expect(noItems.total, 45);
  });

  test('rejects future and very old dates; reads ISO dates', () {
    expect(
      ReceiptParser.parse(['Shop', 'Date 15/12/2026', 'Total 10.00'], now: now)
          .date,
      isNull,
    );
    expect(
      ReceiptParser.parse(['Shop', '2026-10-31', 'Total 10.00'], now: now).date,
      DateTime(2026, 10, 31),
    );
  });

  test('amount extraction skips phone numbers, times and percentages', () {
    expect(ReceiptParser.amountsIn('Ph 9876543210 at 21:14 GST 18%'), isEmpty);
    expect(ReceiptParser.amountsIn('Total Rs.1,23,456.50'), [123456.5]);
  });

  test('empty OCR', () {
    expect(ReceiptParser.parse(const ['  '], now: now).isEmpty, isTrue);
  });
}
