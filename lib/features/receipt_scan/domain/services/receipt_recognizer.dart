/// On-device OCR. Returns the receipt's text as visual rows, top to bottom,
/// with the pieces of each row joined left to right (so "Paneer Tikka" and
/// "240.00" printed on one row come back as one line).
abstract interface class ReceiptRecognizer {
  Future<List<String>> recognize(String imagePath);
  Future<void> dispose();
}
