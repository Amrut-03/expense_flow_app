import '../../../../core/logging/app_log_buffer.dart';
import '../../domain/entities/exchange_rate_entity.dart';
import '../../domain/repositories/currency_repository.dart';
import '../datasources/local/exchange_rate_local_datasource.dart';
import '../datasources/remote/exchange_rate_remote_datasource.dart';

class CurrencyRepositoryImpl implements CurrencyRepository {
  final ExchangeRateRemoteDataSource remote;
  final ExchangeRateLocalDataSource local;

  /// Rates are refreshed at most once per [cacheTtl]; within that window the
  /// locally cached copy is served without touching the network.
  static const Duration cacheTtl = Duration(hours: 24);

  CurrencyRepositoryImpl({required this.remote, required this.local});

  @override
  Future<ExchangeRateEntity> getExchangeRates() async {
    final cached = await local.getCachedRates();
    final fetchedAt = await local.getFetchedAt();

    if (cached != null &&
        fetchedAt != null &&
        DateTime.now().difference(fetchedAt) < cacheTtl) {
      return cached;
    }

    try {
      final rates = await remote.getRates();
      await local.cacheRates(rates);
      return rates;
    } catch (e, st) {
      AppLogBuffer.instance.captureError(
        'currency.getExchangeRates (remote, falling back to cache)',
        e,
        st,
      );
      // The cache is stale or missing and the remote is unreachable: fall
      // back to whatever we still have locally rather than failing.
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
