import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';
import 'app_colors.dart';
import '../../features/settings/domain/repositories/user_settings_repository.dart';

enum AppThemeMode { light, dark }

class ThemeState extends Equatable {
  final AppThemeMode mode;
  final NeuPalette palette;

  const ThemeState(this.mode, this.palette);

  @override
  List<Object?> get props => [mode, palette];
}

class ThemeCubit extends Cubit<ThemeState> {
  static const _boxName = 'settings';
  static const _key = 'is_dark_mode';

  final UserSettingsRepository _settingsRepository;

  ThemeCubit(this._settingsRepository)
    : super(ThemeState(AppThemeMode.light, NeuPalette.light)) {
    _loadSavedTheme();
  }

  Future<void> _loadSavedTheme() async {
    final box = await Hive.openBox(_boxName);
    final isDark = box.get(_key, defaultValue: false) as bool;
    emit(_stateFor(isDark));

    final remote = await _settingsRepository.pullRemote();
    if (remote != null && remote.darkMode != isDark) {
      emit(_stateFor(remote.darkMode));
    }
  }

  Future<void> toggle(bool isDark) async {
    emit(_stateFor(isDark));
    final box = await Hive.openBox(_boxName);
    await box.put(_key, isDark);

    final current = await _settingsRepository.readLocal();
    await _settingsRepository.push(current.copyWith(darkMode: isDark));
  }

  ThemeState _stateFor(bool isDark) => ThemeState(
    isDark ? AppThemeMode.dark : AppThemeMode.light,
    isDark ? NeuPalette.dark : NeuPalette.light,
  );
}
