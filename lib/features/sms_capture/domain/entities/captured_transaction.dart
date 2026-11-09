import 'package:equatable/equatable.dart';

/// A raw inbox SMS as read from the device.
class RawSms extends Equatable {
  final String id;
  final String sender;
  final String body;
  final DateTime receivedAt;

  const RawSms({
    required this.id,
    required this.sender,
    required this.body,
    required this.receivedAt,
  });

  @override
  List<Object?> get props => [id, sender, body, receivedAt];
}

/// The payment details extracted from one bank/UPI SMS.
class ParsedTransaction extends Equatable {
  /// INR.
  final double amount;
  final String? merchant;

  /// One of `PaymentMethods.all`.
  final String paymentMethod;
  final String? reference;

  const ParsedTransaction({
    required this.amount,
    this.merchant,
    required this.paymentMethod,
    this.reference,
  });

  @override
  List<Object?> get props => [amount, merchant, paymentMethod, reference];
}

enum CaptureStatus { pending, accepted, dismissed }

/// A payment detected from SMS, waiting for (or past) user review.
class CapturedTransaction extends Equatable {
  final String id;
  final String smsId;
  final String sender;
  final String body;
  final double amount;
  final String? merchant;
  final String paymentMethod;
  final String? reference;
  final DateTime date;
  final String? suggestedCategoryId;
  final CaptureStatus status;

  /// An expense with the same amount already exists close to this date.
  final bool possibleDuplicate;

  const CapturedTransaction({
    required this.id,
    required this.smsId,
    required this.sender,
    required this.body,
    required this.amount,
    this.merchant,
    required this.paymentMethod,
    this.reference,
    required this.date,
    this.suggestedCategoryId,
    this.status = CaptureStatus.pending,
    this.possibleDuplicate = false,
  });

  CapturedTransaction withStatus(CaptureStatus status) => CapturedTransaction(
    id: id,
    smsId: smsId,
    sender: sender,
    body: body,
    amount: amount,
    merchant: merchant,
    paymentMethod: paymentMethod,
    reference: reference,
    date: date,
    suggestedCategoryId: suggestedCategoryId,
    status: status,
    possibleDuplicate: possibleDuplicate,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'smsId': smsId,
    'sender': sender,
    'body': body,
    'amount': amount,
    'merchant': merchant,
    'paymentMethod': paymentMethod,
    'reference': reference,
    'date': date.toIso8601String(),
    'suggestedCategoryId': suggestedCategoryId,
    'status': status.name,
    'possibleDuplicate': possibleDuplicate,
  };

  static CapturedTransaction? fromMap(Object? raw) {
    if (raw is! Map) return null;
    final id = raw['id'], smsId = raw['smsId'];
    final amount = (raw['amount'] as num?)?.toDouble();
    final date = DateTime.tryParse(raw['date'] as String? ?? '');
    if (id is! String || smsId is! String || amount == null || date == null) {
      return null;
    }
    return CapturedTransaction(
      id: id,
      smsId: smsId,
      sender: raw['sender'] as String? ?? '',
      body: raw['body'] as String? ?? '',
      amount: amount,
      merchant: raw['merchant'] as String?,
      paymentMethod: raw['paymentMethod'] as String? ?? 'Other',
      reference: raw['reference'] as String?,
      date: date,
      suggestedCategoryId: raw['suggestedCategoryId'] as String?,
      status: CaptureStatus.values.firstWhere(
        (s) => s.name == raw['status'],
        orElse: () => CaptureStatus.pending,
      ),
      possibleDuplicate: raw['possibleDuplicate'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [
    id,
    smsId,
    sender,
    body,
    amount,
    merchant,
    paymentMethod,
    reference,
    date,
    suggestedCategoryId,
    status,
    possibleDuplicate,
  ];
}
