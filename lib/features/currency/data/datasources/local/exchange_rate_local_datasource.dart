import 'package:hive/hive.dart';

import '../../models/exchange_rate_model.dart';

abstract class ExchangeRateLocalDataSource {
  Future<void> cacheRates(ExchangeRateModel model);

  Future<ExchangeRateModel?> getCachedRates();

  Future<void> saveSelectedCurrency(String code);

  Future<String> getSelectedCurrency();
}

class ExchangeRateLocalDataSourceImpl implements ExchangeRateLocalDataSource {
  static const _rateBox = 'exchange_rates';
  static const _settingsBox = 'settings';

  @override
  Future<void> cacheRates(ExchangeRateModel model) async {
    final box = await Hive.openBox(_rateBox);

    await box.put('rates', model.rates);

    await box.put('fetched_at', DateTime.now().millisecondsSinceEpoch);
  }

  @override
  Future<ExchangeRateModel?> getCachedRates() async {
    final box = await Hive.openBox(_rateBox);

    final cached = box.get('rates');

    if (cached == null) {
      return null;
    }

    return ExchangeRateModel(Map<String, double>.from(cached));
  }

  @override
  Future<void> saveSelectedCurrency(String code) async {
    final box = await Hive.openBox(_settingsBox);

    await box.put('selected_currency', code);
  }

  @override
  Future<String> getSelectedCurrency() async {
    final box = await Hive.openBox(_settingsBox);

    return box.get('selected_currency', defaultValue: 'INR') ?? 'INR';
  }
}
