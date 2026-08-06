import 'package:equatable/equatable.dart';

class UserSettings extends Equatable {
  final bool darkMode;
  final String currencyCode;
  final String localeCode;

  const UserSettings({
    this.darkMode = false,
    this.currencyCode = 'INR',
    this.localeCode = 'en',
  });

  @override
  List<Object?> get props => [darkMode, currencyCode, localeCode];

  UserSettings copyWith({
    bool? darkMode,
    String? currencyCode,
    String? localeCode,
  }) {
    return UserSettings(
      darkMode: darkMode ?? this.darkMode,
      currencyCode: currencyCode ?? this.currencyCode,
      localeCode: localeCode ?? this.localeCode,
    );
  }
}
