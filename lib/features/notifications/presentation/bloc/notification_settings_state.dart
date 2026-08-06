import 'package:equatable/equatable.dart';

import '../../domain/entities/notification_settings.dart';

sealed class NotificationSettingsState extends Equatable {
  const NotificationSettingsState();

  @override
  List<Object?> get props => [];
}

class NotificationSettingsInitial extends NotificationSettingsState {
  const NotificationSettingsInitial();
}

class NotificationSettingsLoading extends NotificationSettingsState {
  const NotificationSettingsLoading();
}

class NotificationSettingsLoaded extends NotificationSettingsState {
  final NotificationSettings settings;

  const NotificationSettingsLoaded(this.settings);

  @override
  List<Object?> get props => [settings];
}
