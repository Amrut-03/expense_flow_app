import '../../domain/services/currency_converter.dart';

class CurrencyConverterImpl implements CurrencyConverter {
  final Map<String, double> rates;

  CurrencyConverterImpl(this.rates);

  @override
  double convertToInr({required double amount, required String fromCurrency}) {
    if (fromCurrency == 'INR') return amount;

    final fromRate = rates[fromCurrency];
    final inrRate = rates['INR'];
    if (fromRate == null || inrRate == null) return amount;

    final usd = amount / fromRate;
    return usd * inrRate;
  }

  @override
  double convertFromInr({
    required double amountInInr,
    required String toCurrency,
  }) {
    if (toCurrency == 'INR') return amountInInr;

    final inrRate = rates['INR'];
    final toRate = rates[toCurrency];
    if (inrRate == null || toRate == null) return amountInInr;

    final usd = amountInInr / inrRate;
    return usd * toRate;
  }
}
