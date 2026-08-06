import '../entities/exchange_rate_entity.dart';
import '../repositories/currency_repository.dart';

class GetExchangeRatesUseCase {
  final CurrencyRepository repository;

  const GetExchangeRatesUseCase(this.repository);

  Future<ExchangeRateEntity> call() {
    return repository.getExchangeRates();
  }
}
