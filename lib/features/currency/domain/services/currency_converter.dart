abstract class CurrencyConverter {
  double convertToInr({required double amount, required String fromCurrency});

  double convertFromInr({
    required double amountInInr,
    required String toCurrency,
  });
}
