import '../services/currency_converter.dart';

class CreateCurrencyConverterUseCase {
  final CurrencyConverter Function(Map<String, double>) _factory;

  const CreateCurrencyConverterUseCase(this._factory);

  CurrencyConverter call(Map<String, double> rates) => _factory(rates);
}
