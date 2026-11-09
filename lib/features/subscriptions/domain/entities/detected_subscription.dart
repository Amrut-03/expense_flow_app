import 'package:equatable/equatable.dart';

import '../../../recurring/domain/entities/recurring_expense_entity.dart';

/// A repeating charge inferred from expense history.
class DetectedSubscription extends Equatable {
  /// Normalised merchant key the charges were grouped by.
  final String key;

  /// Display name (the most recent merchant/title as the user typed it).
  final String name;
  final String categoryId;
  final String? paymentMethod;

  /// Typical charge in INR (median of observed charges).
  final double amount;
  final RecurrenceFrequency frequency;
  final int occurrences;
  final DateTime firstCharge;
  final DateTime lastCharge;
  final DateTime nextExpected;

  /// Already covered by a recurring rule, so it is logged automatically.
  final bool isTracked;

  const DetectedSubscription({
    required this.key,
    required this.name,
    required this.categoryId,
    this.paymentMethod,
    required this.amount,
    required this.frequency,
    required this.occurrences,
    required this.firstCharge,
    required this.lastCharge,
    required this.nextExpected,
    required this.isTracked,
  });

  /// Cost over a year at the detected frequency.
  double get annualCost => switch (frequency) {
    RecurrenceFrequency.daily => amount * 365,
    RecurrenceFrequency.weekly => amount * 52,
    RecurrenceFrequency.monthly => amount * 12,
    RecurrenceFrequency.yearly => amount,
  };

  /// Equivalent monthly cost, for "₹X/month on subscriptions" totals.
  double get monthlyCost => annualCost / 12;

  @override
  List<Object?> get props => [
    key,
    name,
    categoryId,
    paymentMethod,
    amount,
    frequency,
    occurrences,
    firstCharge,
    lastCharge,
    nextExpected,
    isTracked,
  ];
}
