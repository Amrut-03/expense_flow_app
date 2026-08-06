import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/repositories/user_settings_repository.dart';

/// App languages. Order matters: it drives the language picker and
/// `AppLocalizations.supportedLocales` resolution.
const appLocales = [Locale('en'), Locale('hi'), Locale('mr')];

class LocaleCubit extends Cubit<Locale> {
  final UserSettingsRepository _settingsRepository;

  LocaleCubit(this._settingsRepository) : super(appLocales.first);

  Future<void> initialize() async {
    final settings = await _settingsRepository.readLocal();
    emit(Locale(settings.localeCode));
  }

  Future<void> setLocale(Locale locale) async {
    emit(locale);

    final settings = await _settingsRepository.readLocal();
    final updated = settings.copyWith(localeCode: locale.languageCode);

    await _settingsRepository.updateLocal(updated);
    await _settingsRepository.push(updated);
  }
}
