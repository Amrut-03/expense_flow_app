import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/notification_settings.dart';
import '../../domain/usecases/get_notification_settings_usecase.dart';
import '../../domain/usecases/update_notification_settings_usecase.dart';
import 'notification_settings_state.dart';

/// Loads the persisted notification preferences, applies enable/disable
/// toggles, and re-schedules pending notifications via [onReschedule] (wired
/// in DI to `NotificationScheduler.scheduleAll`).
class NotificationSettingsCubit extends Cubit<NotificationSettingsState> {
  final GetNotificationSettingsUseCase getSettings;
  final UpdateNotificationSettingsUseCase updateSettings;
  final Future<void> Function() onReschedule;

  NotificationSettingsCubit({
    required this.getSettings,
    required this.updateSettings,
    required this.onReschedule,
  }) : super(const NotificationSettingsInitial());

  Future<void> load() async {
    emit(const NotificationSettingsLoading());
    emit(NotificationSettingsLoaded(getSettings()));
  }

  Future<void> setBudgetAlertsEnabled(bool enabled) =>
      _update((s) => s.copyWith(budgetAlertsEnabled: enabled));

  Future<void> setDailyReminderEnabled(bool enabled) =>
      _update((s) => s.copyWith(dailyReminderEnabled: enabled));

  Future<void> setWeeklySummaryEnabled(bool enabled) =>
      _update((s) => s.copyWith(weeklySummaryEnabled: enabled));

  Future<void> setMonthlySummaryEnabled(bool enabled) =>
      _update((s) => s.copyWith(monthlySummaryEnabled: enabled));

  Future<void> _update(
    NotificationSettings Function(NotificationSettings) transform,
  ) async {
    final current = state is NotificationSettingsLoaded
        ? (state as NotificationSettingsLoaded).settings
        : getSettings();
    final updated = transform(current);

    await updateSettings(updated);
    emit(NotificationSettingsLoaded(updated));
    await onReschedule();
  }
}
