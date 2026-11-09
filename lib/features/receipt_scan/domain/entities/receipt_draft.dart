import 'package:equatable/equatable.dart';

class ReceiptLineItem extends Equatable {
  final String name;

  /// Line amount in INR.
  final double amount;

  const ReceiptLineItem(this.name, this.amount);

  @override
  List<Object?> get props => [name, amount];
}

/// What could be read off a receipt. Every field is optional: the user
/// reviews the draft before anything is saved.
class ReceiptDraft extends Equatable {
  /// Grand total in INR.
  final double? total;
  final String? merchant;
  final DateTime? date;

  /// GST (CGST + SGST, or IGST) when printed.
  final double? tax;
  final List<ReceiptLineItem> items;

  /// One of `PaymentMethods.all`.
  final String? paymentMethod;
  final String? categoryId;

  /// OCR text, for the "show text" fallback.
  final List<String> lines;

  const ReceiptDraft({
    this.total,
    this.merchant,
    this.date,
    this.tax,
    this.items = const [],
    this.paymentMethod,
    this.categoryId,
    this.lines = const [],
  });

  bool get isEmpty => total == null && merchant == null && items.isEmpty;

  double get itemsTotal => items.fold(0, (s, i) => s + i.amount);

  ReceiptDraft copyWith({String? categoryId}) => ReceiptDraft(
    total: total,
    merchant: merchant,
    date: date,
    tax: tax,
    items: items,
    paymentMethod: paymentMethod,
    categoryId: categoryId ?? this.categoryId,
    lines: lines,
  );

  @override
  List<Object?> get props => [
    total,
    merchant,
    date,
    tax,
    items,
    paymentMethod,
    categoryId,
    lines,
  ];
}
