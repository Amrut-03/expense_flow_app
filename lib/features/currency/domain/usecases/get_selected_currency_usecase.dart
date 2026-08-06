import '../repositories/currency_repository.dart';

class GetSelectedCurrencyUseCase {
  final CurrencyRepository repository;

  const GetSelectedCurrencyUseCase(this.repository);

  Future<String> call() {
    return repository.getSelectedCurrency();
  }
}
