import '../entities/exchange_rate_entity.dart';

abstract class CurrencyRepository {
  Future<ExchangeRateEntity> getExchangeRates();

  Future<void> saveSelectedCurrency(String code);

  Future<String> getSelectedCurrency();
}
