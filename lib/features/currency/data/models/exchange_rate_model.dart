import '../../domain/entities/exchange_rate_entity.dart';

class ExchangeRateModel extends ExchangeRateEntity {
  const ExchangeRateModel(super.rates);

  factory ExchangeRateModel.fromJson(Map<String, dynamic> json) {
    final rates = (json['rates'] as Map<String, dynamic>).map(
      (key, value) => MapEntry(key, (value as num).toDouble()),
    );

    return ExchangeRateModel(rates);
  }
}
