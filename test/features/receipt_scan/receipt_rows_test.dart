import 'package:expense_flow_app/features/receipt_scan/data/mlkit_receipt_recognizer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('joins segments printed on the same row, left to right', () {
    final rows = ReceiptRows.merge(const [
      OcrSegment('640.00', top: 102, bottom: 120, left: 300),
      OcrSegment('MEGHANA FOODS', top: 10, bottom: 30, left: 80),
      OcrSegment('Chicken Biryani', top: 100, bottom: 118, left: 20),
      OcrSegment('Paneer Tikka', top: 125, bottom: 143, left: 20),
      OcrSegment('280.00', top: 127, bottom: 145, left: 300),
    ]);
    expect(rows, [
      'MEGHANA FOODS',
      'Chicken Biryani 640.00',
      'Paneer Tikka 280.00',
    ]);
  });
}
