import '../cubit/currency_cubit.dart';

class CurrencyFormatter {
  CurrencyFormatter._();

  static String format({
    required CurrencyCubit cubit,
    required double amountInInr,
  }) {
    final converted = cubit.convertFromInr(amountInInr);

    final symbol = cubit.state.selected.symbol;

    final sign = converted < 0 ? '-' : '';

    return '$sign$symbol${converted.abs().toStringAsFixed(2)}';
  }
}
