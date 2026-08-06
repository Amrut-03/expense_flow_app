import 'package:equatable/equatable.dart';

import '../../domain/entities/app_currency.dart';

class CurrencyState extends Equatable {
  static const _unset = Object();

  final AppCurrency selected;
  final Map<String, double> rates;
  final bool isLoading;
  final String? rateError;

  const CurrencyState({
    required this.selected,
    required this.rates,
    this.isLoading = false,
    this.rateError,
  });

  factory CurrencyState.initial() {
    return CurrencyState(
      selected: supportedCurrencies.first,
      rates: const {},
      isLoading: true,
    );
  }

  CurrencyState copyWith({
    AppCurrency? selected,
    Map<String, double>? rates,
    bool? isLoading,
    Object? rateError = _unset,
  }) {
    return CurrencyState(
      selected: selected ?? this.selected,
      rates: rates ?? this.rates,
      isLoading: isLoading ?? this.isLoading,
      rateError: identical(rateError, _unset)
          ? this.rateError
          : rateError as String?,
    );
  }

  @override
  List<Object?> get props => [selected, rates, isLoading, rateError];
}
