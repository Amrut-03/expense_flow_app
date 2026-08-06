import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/error_formatter.dart';
import '../../../../features/settings/domain/repositories/user_settings_repository.dart';
import '../../domain/entities/app_currency.dart';
import '../../domain/services/currency_converter.dart';
import '../../domain/usecases/change_currency_usecase.dart';
import '../../domain/usecases/create_currency_converter_usecase.dart';
import '../../domain/usecases/get_exchange_rate_usecase.dart';
import '../../domain/usecases/get_selected_currency_usecase.dart';
import 'currency_state.dart';

class CurrencyCubit extends Cubit<CurrencyState> {
  final GetExchangeRatesUseCase getRates;
  final ChangeCurrencyUseCase changeCurrencyUseCase;
  final GetSelectedCurrencyUseCase getSelectedCurrencyUseCase;
  final CreateCurrencyConverterUseCase createConverter;
  final UserSettingsRepository _settingsRepository;

  CurrencyConverter? _converter;

  CurrencyCubit(
    this._settingsRepository, {
    required this.getRates,
    required this.changeCurrencyUseCase,
    required this.getSelectedCurrencyUseCase,
    required this.createConverter,
  }) : super(CurrencyState.initial());

  Future<void> initialize() async {
    final selectedCode = await getSelectedCurrencyUseCase();

    final selected = supportedCurrencies.firstWhere(
      (e) => e.code == selectedCode,
      orElse: () => supportedCurrencies.first,
    );

    var rates = const <String, double>{};
    String? rateError;

    try {
      final ratesEntity = await getRates();
      rates = ratesEntity.rates;
      _converter = createConverter(rates);
    } on Exception catch (e) {
      rateError = friendlyError(e);
    }

    emit(
      state.copyWith(
        selected: selected,
        rates: rates,
        rateError: rateError,
        isLoading: false,
      ),
    );

    final remote = await _settingsRepository.pullRemote();
    if (remote != null && remote.currencyCode != selected.code) {
      final remoteSelected = supportedCurrencies.firstWhere(
        (e) => e.code == remote.currencyCode,
        orElse: () => selected,
      );
      emit(state.copyWith(selected: remoteSelected));
    }
  }

  Future<void> changeCurrency(AppCurrency currency) async {
    await _ensureConverter();

    if (currency.code != 'INR' && _converter == null) {
      emit(
        state.copyWith(
          rateError:
              'Live exchange rates are unavailable. '
              'Amounts are shown in INR.',
        ),
      );
      return;
    }

    await changeCurrencyUseCase(currency.code);

    emit(state.copyWith(selected: currency));

    final current = await _settingsRepository.readLocal();
    await _settingsRepository.push(
      current.copyWith(currencyCode: currency.code),
    );
  }

  double convertFromInr(double amountInInr) {
    final converter = _converter;

    if (converter == null) {
      return amountInInr;
    }

    return converter.convertFromInr(
      amountInInr: amountInInr,
      toCurrency: state.selected.code,
    );
  }

  double convertToInr({required double amount, required String fromCurrency}) {
    final converter = _converter;

    if (converter == null) {
      return amount;
    }

    return converter.convertToInr(amount: amount, fromCurrency: fromCurrency);
  }

  Future<void> _ensureConverter() async {
    if (_converter != null) return;

    try {
      final ratesEntity = await getRates();
      _converter = createConverter(ratesEntity.rates);
      emit(state.copyWith(rates: ratesEntity.rates, rateError: null));
    } on Exception catch (e) {
      emit(state.copyWith(rateError: friendlyError(e)));
    }
  }
}
