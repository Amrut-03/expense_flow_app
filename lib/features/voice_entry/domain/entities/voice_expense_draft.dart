import 'package:equatable/equatable.dart';

/// What was understood from a spoken expense. Every field is optional; the
/// form is pre-filled and the user confirms before saving.
class VoiceExpenseDraft extends Equatable {
  final String transcript;
  final double? amount;

  /// True when the user said rupees (₹, "rupees", "रुपये"…), so [amount] is
  /// INR regardless of the display currency.
  final bool amountIsInr;
  final String? title;
  final String? merchant;
  final String? categoryId;

  /// One of `PaymentMethods.all`.
  final String? paymentMethod;

  /// True when the on-device model filled in or improved fields.
  final bool refinedByModel;

  const VoiceExpenseDraft({
    required this.transcript,
    this.amount,
    this.amountIsInr = false,
    this.title,
    this.merchant,
    this.categoryId,
    this.paymentMethod,
    this.refinedByModel = false,
  });

  bool get isEmpty =>
      amount == null &&
      title == null &&
      merchant == null &&
      categoryId == null &&
      paymentMethod == null;

  /// Missing something the model could plausibly add.
  bool get isIncomplete => amount == null || categoryId == null;

  VoiceExpenseDraft copyWith({
    double? amount,
    String? title,
    String? merchant,
    String? categoryId,
    String? paymentMethod,
    bool? refinedByModel,
  }) {
    return VoiceExpenseDraft(
      transcript: transcript,
      amount: amount ?? this.amount,
      amountIsInr: amountIsInr,
      title: title ?? this.title,
      merchant: merchant ?? this.merchant,
      categoryId: categoryId ?? this.categoryId,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      refinedByModel: refinedByModel ?? this.refinedByModel,
    );
  }

  @override
  List<Object?> get props => [
    transcript,
    amount,
    amountIsInr,
    title,
    merchant,
    categoryId,
    paymentMethod,
    refinedByModel,
  ];
}
