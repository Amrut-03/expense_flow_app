import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../domain/services/receipt_recognizer.dart';

/// ML Kit on-device text recognition (Latin script model bundled with the
/// app; no network, the image never leaves the phone).
class MlKitReceiptRecognizer implements ReceiptRecognizer {
  TextRecognizer? _recognizer;

  @override
  Future<List<String>> recognize(String imagePath) async {
    final recognizer = _recognizer ??= TextRecognizer();
    final result = await recognizer.processImage(
      InputImage.fromFilePath(imagePath),
    );
    return ReceiptRows.merge([
      for (final block in result.blocks)
        for (final line in block.lines)
          OcrSegment(
            line.text,
            top: line.boundingBox.top,
            bottom: line.boundingBox.bottom,
            left: line.boundingBox.left,
          ),
    ]);
  }

  @override
  Future<void> dispose() async {
    await _recognizer?.close();
    _recognizer = null;
  }
}

class OcrSegment {
  const OcrSegment(
    this.text, {
    required this.top,
    required this.bottom,
    required this.left,
  });

  final String text;
  final double top;
  final double bottom;
  final double left;

  double get centre => (top + bottom) / 2;
  double get height => bottom - top;
}

/// Receipts print "item ...... price" on one row, but OCR returns the two
/// sides as separate blocks. Segments whose vertical centres are within half
/// a line height are one row; rows are read top→bottom, left→right.
abstract final class ReceiptRows {
  static List<String> merge(List<OcrSegment> segments) {
    final sorted = [...segments]..sort((a, b) => a.centre.compareTo(b.centre));
    final rows = <List<OcrSegment>>[];
    for (final s in sorted) {
      final row = rows.isEmpty ? null : rows.last;
      if (row != null) {
        final rowCentre =
            row.fold<double>(0, (sum, r) => sum + r.centre) / row.length;
        final tolerance = row.first.height * .5;
        if ((s.centre - rowCentre).abs() <= tolerance) {
          row.add(s);
          continue;
        }
      }
      rows.add([s]);
    }
    return [
      for (final row in rows)
        (row..sort((a, b) => a.left.compareTo(b.left)))
            .map((s) => s.text.trim())
            .join(' '),
    ];
  }
}
