import 'package:expense_flow_app/core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/theme_cubit.dart';
import '../../../../features/settings/presentation/widgets/setting_tile.dart';
import '../../../../core/notifications/logging_time_learner.dart';
import '../bloc/notification_settings_cubit.dart';
import '../bloc/notification_settings_state.dart';

/// Lets the user enable/disable each notification channel. Changes are
/// persisted locally and immediately rescheduled.
class NotificationSettingsScreen extends StatelessWidget {
  const NotificationSettingsScreen({super.key, this.loggingTime});

  /// Learned usual logging time, shown under the reminder toggle.
  final Future<LoggingTime> Function()? loggingTime;

  @override
  Widget build(BuildContext context) {
    final palette = context.watch<ThemeCubit>().state.palette;

    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        child:
            BlocBuilder<NotificationSettingsCubit, NotificationSettingsState>(
              builder: (context, state) {
                final cubit = context.read<NotificationSettingsCubit>();
                final settings = state is NotificationSettingsLoaded
                    ? state.settings
                    : null;

                return SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: 24.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 10.h),
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.of(context).maybePop(),
                            child: Icon(
                              Icons.arrow_back_ios_new_rounded,
                              size: 18.sp,
                              color: palette.textDark,
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Text(
                            'Notifications',
                            style: AppTextStyles.manrope(
                              fontSize: 26.sp,
                              fontWeight: FontWeight.bold,
                              color: palette.textDark,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 6.h),
                      Text(
                        'Choose which alerts you receive.',
                        style: AppTextStyles.manrope(
                          fontSize: 13.sp,
                          color: palette.textDark.withValues(alpha: .5),
                        ),
                      ),
                      SizedBox(height: 20.h),

                      _sectionTitle(context, 'Budget alerts')
                          .animate()
                          .fadeIn(duration: 260.ms, curve: Curves.easeOut)
                          .slideY(
                            begin: 0.05,
                            end: 0,
                            curve: Curves.easeOutCubic,
                          ),
                      SizedBox(height: 10.h),
                      SettingsTile(
                            emoji: '🎯',
                            label: 'Budget alerts',
                            trailing: Switch(
                              value: settings?.budgetAlertsEnabled ?? true,
                              activeThumbColor: palette.accent,
                              onChanged: settings == null
                                  ? null
                                  : cubit.setBudgetAlertsEnabled,
                            ),
                          )
                          .animate(delay: 60.ms)
                          .fadeIn(duration: 260.ms, curve: Curves.easeOut)
                          .slideY(
                            begin: 0.05,
                            end: 0,
                            curve: Curves.easeOutCubic,
                          ),
                      SizedBox(height: 12.h),

                      _sectionTitle(context, 'Reminders')
                          .animate(delay: 140.ms)
                          .fadeIn(duration: 260.ms, curve: Curves.easeOut),
                      SizedBox(height: 10.h),
                      _LoggingReminderTile(
                            enabled: settings?.dailyReminderEnabled ?? true,
                            onChanged: settings == null
                                ? null
                                : cubit.setDailyReminderEnabled,
                            loggingTime: loggingTime,
                          )
                          .animate(delay: 200.ms)
                          .fadeIn(duration: 260.ms, curve: Curves.easeOut)
                          .slideY(
                            begin: 0.05,
                            end: 0,
                            curve: Curves.easeOutCubic,
                          ),
                      SizedBox(height: 12.h),

                      _sectionTitle(context, 'Summaries')
                          .animate(delay: 280.ms)
                          .fadeIn(duration: 260.ms, curve: Curves.easeOut),
                      SizedBox(height: 10.h),
                      SettingsTile(
                            emoji: '📊',
                            label: 'Weekly summary',
                            trailing: Switch(
                              value: settings?.weeklySummaryEnabled ?? true,
                              activeThumbColor: palette.accent,
                              onChanged: settings == null
                                  ? null
                                  : cubit.setWeeklySummaryEnabled,
                            ),
                          )
                          .animate(delay: 340.ms)
                          .fadeIn(duration: 260.ms, curve: Curves.easeOut)
                          .slideY(
                            begin: 0.05,
                            end: 0,
                            curve: Curves.easeOutCubic,
                          ),
                      SizedBox(height: 12.h),
                      SettingsTile(
                            emoji: '📈',
                            label: 'Monthly summary',
                            trailing: Switch(
                              value: settings?.monthlySummaryEnabled ?? true,
                              activeThumbColor: palette.accent,
                              onChanged: settings == null
                                  ? null
                                  : cubit.setMonthlySummaryEnabled,
                            ),
                          )
                          .animate(delay: 400.ms)
                          .fadeIn(duration: 260.ms, curve: Curves.easeOut)
                          .slideY(
                            begin: 0.05,
                            end: 0,
                            curve: Curves.easeOutCubic,
                          ),
                      SizedBox(height: 12.h),
                      SettingsTile(
                        emoji: '🧾',
                        label: AppLocalizations.of(context).notif_billReminders,
                        trailing: Switch(
                          value: settings?.billRemindersEnabled ?? true,
                          activeThumbColor: palette.accent,
                          onChanged: settings == null
                              ? null
                              : cubit.setBillRemindersEnabled,
                        ),
                      ).animate(delay: 440.ms).fadeIn(duration: 260.ms),
                      SizedBox(height: 12.h),
                      SettingsTile(
                        emoji: '💸',
                        label: AppLocalizations.of(context).notif_captureAlerts,
                        trailing: Switch(
                          value: settings?.captureAlertsEnabled ?? true,
                          activeThumbColor: palette.accent,
                          onChanged: settings == null
                              ? null
                              : cubit.setCaptureAlertsEnabled,
                        ),
                      ).animate(delay: 470.ms).fadeIn(duration: 260.ms),
                      SizedBox(height: 24.h),
                    ],
                  ),
                );
              },
            ),
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String text) {
    final palette = context.watch<ThemeCubit>().state.palette;
    return Text(
      text,
      style: AppTextStyles.manrope(
        fontSize: 13.sp,
        fontWeight: FontWeight.w600,
        color: palette.textDark.withValues(alpha: .5),
      ),
    );
  }
}

class _LoggingReminderTile extends StatefulWidget {
  const _LoggingReminderTile({
    required this.enabled,
    required this.onChanged,
    required this.loggingTime,
  });

  final bool enabled;
  final ValueChanged<bool>? onChanged;
  final Future<LoggingTime> Function()? loggingTime;

  @override
  State<_LoggingReminderTile> createState() => _LoggingReminderTileState();
}

class _LoggingReminderTileState extends State<_LoggingReminderTile> {
  late final Future<LoggingTime>? _time = widget.loggingTime?.call();

  @override
  Widget build(BuildContext context) {
    final palette = context.watch<ThemeCubit>().state.palette;
    final l10n = AppLocalizations.of(context);
    return FutureBuilder<LoggingTime>(
      future: _time,
      builder: (context, snapshot) {
        final time = snapshot.data;
        String? subtitle;
        if (time != null) {
          final formatted = TimeOfDay(
            hour: time.hour,
            minute: time.minute,
          ).format(context);
          subtitle = time.learned
              ? l10n.notif_loggingLearned(formatted)
              : l10n.notif_loggingDefault(formatted);
        }
        return SettingsTile(
          emoji: '🌙',
          label: l10n.notif_loggingReminder,
          subtitle: subtitle,
          trailing: Switch(
            value: widget.enabled,
            activeThumbColor: palette.accent,
            onChanged: widget.onChanged,
          ),
        );
      },
    );
  }
}
