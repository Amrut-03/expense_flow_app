import 'package:hive/hive.dart';
import '../../../domain/entities/user_settings.dart';

abstract class SettingsLocalDataSource {
  Future<UserSettings> read();
  Future<void> write(UserSettings settings);
}

class SettingsLocalDataSourceImpl implements SettingsLocalDataSource {
  static const _boxName = 'settings';

  @override
  Future<UserSettings> read() async {
    final box = await Hive.openBox(_boxName);
    return UserSettings(
      darkMode: box.get('is_dark_mode', defaultValue: false) as bool? ?? false,
      currencyCode:
          box.get('selected_currency', defaultValue: 'INR') as String? ?? 'INR',
      localeCode: box.get('locale_code', defaultValue: 'en') as String? ?? 'en',
    );
  }

  @override
  Future<void> write(UserSettings settings) async {
    final box = await Hive.openBox(_boxName);
    await box.put('is_dark_mode', settings.darkMode);
    await box.put('selected_currency', settings.currencyCode);
    await box.put('locale_code', settings.localeCode);
  }
}
