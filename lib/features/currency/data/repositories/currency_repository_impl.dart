import '../../domain/entities/exchange_rate_entity.dart';
import '../../domain/repositories/currency_repository.dart';
import '../datasources/local/exchange_rate_local_datasource.dart';
import '../datasources/remote/exchange_rate_remote_datasource.dart';

class CurrencyRepositoryImpl implements CurrencyRepository {
  final ExchangeRateRemoteDataSource remote;
  final ExchangeRateLocalDataSource local;

  CurrencyRepositoryImpl({required this.remote, required this.local});

  @override
  Future<ExchangeRateEntity> getExchangeRates() async {
    try {
      final rates = await remote.getRates();
      await local.cacheRates(rates);
      return rates;
    } catch (_) {
      final cached = await local.getCachedRates();

      if (cached != null) {
        return cached;
      }

      rethrow;
    }
  }

  @override
  Future<void> saveSelectedCurrency(String code) {
    return local.saveSelectedCurrency(code);
  }

  @override
  Future<String> getSelectedCurrency() {
    return local.getSelectedCurrency();
  }
}
