import '../repositories/currency_repository.dart';

class ChangeCurrencyUseCase {
  final CurrencyRepository repository;

  const ChangeCurrencyUseCase(this.repository);

  Future<void> call(String code) {
    return repository.saveSelectedCurrency(code);
  }
}
