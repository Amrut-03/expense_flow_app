import 'package:expense_flow_app/core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import '../../../../core/logging/app_log_buffer.dart';
import '../../../../core/logging/log_pdf_generator.dart';
import '../../../../core/theme/neumorphic_styles.dart';
import '../../../../core/theme/theme_cubit.dart';
import '../../../../core/utils/user_display_name.dart';
import '../../../../core/widgets/neu_avatar.dart';
import '../../../../core/widgets/neu_button.dart';
import '../../../../core/widgets/neu_bottom_sheet.dart';
import '../../../../core/widgets/neu_snack_bar.dart';
import '../../../../core/widgets/neu_text_field.dart';
import '../../../../core/widgets/tab_reveal.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../currency/presentation/cubit/currency_cubit.dart';
import '../../../currency/presentation/cubit/currency_state.dart';
import '../../../currency/presentation/widgets/currency_picker.dart';
import '../cubit/locale_cubit.dart';
import '../widgets/setting_tile.dart';

class SettingScreen extends StatefulWidget {
  const SettingScreen({super.key});

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  bool _awaitingEdit = false;
  String _displayName = 'Guest';
  String _email = '';
  String? _photoUrl;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final state = context.read<AuthBloc>().state;
    if (state is Authenticated) _absorb(state.user);
  }

  void _absorb(UserEntity user) {
    _displayName = user.displayNameOrFallback;
    _email = user.email?.trim() ?? '';
    final photo = user.photoUrl?.trim();
    _photoUrl = photo != null && photo.isNotEmpty ? photo : null;
  }

  String get _avatarInitial => _displayName.substring(0, 1).toUpperCase();

  String get _notificationsLabel => 'Customize';

  @override
  Widget build(BuildContext context) {
    final palette = context.watch<ThemeCubit>().state.palette;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: palette.background,
      body: TabReveal(
        child: SafeArea(
          child: BlocListener<AuthBloc, AuthState>(
            listener: (context, state) {
              if (state is Unauthenticated) {
                context.go('/login');
              } else if (state is Authenticated) {
                setState(() {
                  _absorb(state.user);
                  if (_awaitingEdit) {
                    _awaitingEdit = false;
                    NeuSnackBar.show(
                      context: context,
                      message: l10n.auth_profileUpdated,
                      type: NeuSnackBarType.success,
                    );
                  }
                });
              } else if (state is AuthError) {
                NeuSnackBar.show(
                  context: context,
                  message: state.message,
                  type: NeuSnackBarType.error,
                );
              }
            },
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 10.h),
                  Text(
                    l10n.settings_title,
                    style: AppTextStyles.manrope(
                      fontSize: 26.sp,
                      fontWeight: FontWeight.bold,
                      color: palette.textDark,
                    ),
                  ),
                  SizedBox(height: 20.h),

                  // profile card
                  GestureDetector(
                        onTap: _showEditSheet,
                        child: Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(16.w),
                          decoration: NeuBox.raised(palette, radius: 20.r),
                          child: Column(
                            children: [
                              NeuAvatar(
                                photoUrl: _photoUrl,
                                initial: _avatarInitial,
                              ),
                              SizedBox(height: 12.h),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Flexible(
                                    child: Text(
                                      _displayName,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTextStyles.manrope(
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.w600,
                                        color: palette.textDark,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 6.w),
                                  Icon(
                                    Icons.edit_rounded,
                                    color: palette.textDark.withValues(
                                      alpha: .4,
                                    ),
                                    size: 16.sp,
                                  ),
                                ],
                              ),
                              if (_email.isNotEmpty) ...[
                                SizedBox(height: 4.h),
                                Text(
                                  _email,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.manrope(
                                    fontSize: 12.sp,
                                    color: palette.textDark.withValues(
                                      alpha: .5,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      )
                      .animate()
                      .fadeIn(duration: 300.ms, curve: Curves.easeOut)
                      .slideY(begin: 0.06, end: 0, curve: Curves.easeOutCubic),
                  SizedBox(height: 16.h),

                  SettingsTile(
                        emoji: '🌙',
                        label: l10n.settings_darkMode,
                        trailing: BlocBuilder<ThemeCubit, ThemeState>(
                          builder: (context, themeState) {
                            return Switch(
                              value: themeState.mode == AppThemeMode.dark,
                              activeThumbColor: palette.accent,
                              onChanged: (value) =>
                                  context.read<ThemeCubit>().toggle(value),
                            );
                          },
                        ),
                      )
                      .animate(delay: 80.ms)
                      .fadeIn(duration: 260.ms, curve: Curves.easeOut)
                      .slideY(begin: 0.06, end: 0, curve: Curves.easeOutCubic),
                  SizedBox(height: 12.h),
                  SettingsTile(
                        emoji: '🔔',
                        label: l10n.settings_notifications,
                        trailing: ValueChevron(value: _notificationsLabel),
                        onTap: () => context.push('/notification-settings'),
                      )
                      .animate(delay: 160.ms)
                      .fadeIn(duration: 260.ms, curve: Curves.easeOut)
                      .slideY(begin: 0.06, end: 0, curve: Curves.easeOutCubic),
                  SizedBox(height: 12.h),
                  SettingsTile(
                        emoji: '🔄',
                        label: l10n.settings_currency,
                        trailing: BlocBuilder<CurrencyCubit, CurrencyState>(
                          builder: (context, currencyState) {
                            return ValueChevron(
                              value: currencyState.selected.code,
                            );
                          },
                        ),
                        onTap: () => CurrencyPicker.show(context),
                      )
                      .animate(delay: 240.ms)
                      .fadeIn(duration: 260.ms, curve: Curves.easeOut)
                      .slideY(begin: 0.06, end: 0, curve: Curves.easeOutCubic),
                  SizedBox(height: 12.h),
                  SettingsTile(
                        emoji: '🌐',
                        label: AppLocalizations.of(context).common_language,
                        trailing: BlocBuilder<LocaleCubit, Locale>(
                          builder: (context, locale) {
                            return ValueChevron(
                              value: _localeLabel(locale.languageCode),
                            );
                          },
                        ),
                        onTap: () => _showLanguagePicker(context),
                      )
                      .animate(delay: 320.ms)
                      .fadeIn(duration: 260.ms, curve: Curves.easeOut)
                      .slideY(begin: 0.06, end: 0, curve: Curves.easeOutCubic),
                  SizedBox(height: 12.h),
                  SettingsTile(
                        emoji: '📄',
                        label: l10n.settings_logReport,
                        trailing: const ValueChevron(value: 'PDF'),
                        onTap: _createLogReport,
                      )
                      .animate(delay: 360.ms)
                      .fadeIn(duration: 260.ms, curve: Curves.easeOut)
                      .slideY(begin: 0.06, end: 0, curve: Curves.easeOutCubic),
                  SizedBox(height: 12.h),
                  SettingsTile(
                        emoji: '🚪',
                        label: l10n.auth_logOut,
                        trailing: Icon(
                          Icons.chevron_right,
                          color: palette.textDark.withValues(alpha: .4),
                          size: 20.sp,
                        ),
                        onTap: _confirmSignOut,
                      )
                      .animate(delay: 440.ms)
                      .fadeIn(duration: 260.ms, curve: Curves.easeOut)
                      .slideY(begin: 0.06, end: 0, curve: Curves.easeOutCubic),
                  SizedBox(height: 24.h),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showEditSheet() {
    final palette = context.read<ThemeCubit>().state.palette;
    final controller = TextEditingController(text: _displayName);
    final formKey = GlobalKey<FormState>();
    final l10n = AppLocalizations.of(context);

    NeuBottomSheet.show<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SheetDragHandle(),
                  SizedBox(height: 20.h),
                  Text(
                    l10n.settings_editName,
                    style: AppTextStyles.manrope(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                      color: palette.textDark,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    l10n.settings_editNameSubtitle,
                    style: AppTextStyles.manrope(
                      fontSize: 13.sp,
                      color: palette.textDark.withValues(alpha: .6),
                    ),
                  ),
                  SizedBox(height: 16.h),
                  NeuTextField(
                    controller: controller,
                    hint: l10n.settings_yourName,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.name],
                    validator: (value) => value == null || value.trim().isEmpty
                        ? l10n.settings_nameCannotBeEmpty
                        : null,
                    onFieldSubmitted: (_) =>
                        _saveName(context, formKey, controller),
                  ),
                  SizedBox(height: 16.h),
                  NeuButton(
                    label: l10n.common_save,
                    onTap: () => _saveName(context, formKey, controller),
                  ),
                  SizedBox(height: 12.h),
                ],
              ),
            ),
          ),
        );
      },
    ).whenComplete(() => controller.dispose());
  }

  void _saveName(
    BuildContext ctx,
    GlobalKey<FormState> formKey,
    TextEditingController controller,
  ) {
    if (!(formKey.currentState?.validate() ?? false)) return;
    final name = controller.text.trim();
    Navigator.of(ctx).pop();
    setState(() => _awaitingEdit = true);
    context.read<AuthBloc>().add(UpdateProfileRequested(displayName: name));
  }

  /// Captures everything buffered since app start into a PDF and hands it to
  /// the system share sheet so the user can save/send it as a bug report.
  Future<void> _createLogReport() async {
    final palette = context.read<ThemeCubit>().state.palette;
    final l10n = AppLocalizations.of(context);

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 18.h),
          decoration: NeuBox.raised(palette, radius: 20.r),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 22.r,
                height: 22.r,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: palette.accent,
                ),
              ),
              SizedBox(width: 14.w),
              Flexible(
                child: Text(
                  l10n.settings_logReportGenerating,
                  style: AppTextStyles.manrope(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: palette.textDark,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    File? file;
    try {
      file = await LogPdfGenerator().generate();
    } catch (e, st) {
      AppLogBuffer.instance.captureError('settings.logReport.generate', e, st);
      file = null;
    }

    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pop();

    if (file == null) {
      NeuSnackBar.show(
        context: context,
        message: l10n.settings_logReportFailed,
        type: NeuSnackBarType.error,
      );
      return;
    }

    try {
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          text: 'ExpenseFlow log report',
        ),
      );
      if (mounted) {
        NeuSnackBar.show(
          context: context,
          message: l10n.settings_logReportReady,
          type: NeuSnackBarType.success,
        );
      }
    } catch (e, st) {
      AppLogBuffer.instance.captureError('settings.logReport.share', e, st);
      if (mounted) {
        NeuSnackBar.show(
          context: context,
          message: l10n.settings_logReportFailed,
          type: NeuSnackBarType.error,
        );
      }
    }
  }

  Future<void> _confirmSignOut() async {    final palette = context.read<ThemeCubit>().state.palette;
    final l10n = AppLocalizations.of(context);

    final confirmed = await NeuBottomSheet.show<bool>(
      context: context,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SheetDragHandle(),
              SizedBox(height: 20.h),
              Text(
                l10n.auth_logOutQuestion,
                style: AppTextStyles.manrope(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                  color: palette.textDark,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                l10n.auth_logOutSubtitle,
                style: AppTextStyles.manrope(
                  fontSize: 13.sp,
                  color: palette.textDark.withValues(alpha: .6),
                ),
              ),
              SizedBox(height: 16.h),
              NeuButton(
                label: l10n.common_cancel,
                onTap: () => Navigator.of(sheetContext).pop(false),
              ),
              SizedBox(height: 12.h),
              NeuButton(
                label: l10n.auth_logOut,
                onTap: () => Navigator.of(sheetContext).pop(true),
                bgColor: palette.accent,
              ),
              SizedBox(height: 12.h),
            ],
          ),
        );
      },
    );

    if (confirmed == true && mounted) {
      context.read<AuthBloc>().add(SignOutRequested());
    }
  }

  String _localeLabel(String code) {
    switch (code) {
      case 'hi':
        return 'हिंदी';
      case 'mr':
        return 'मराठी';
      default:
        return 'English';
    }
  }

  void _showLanguagePicker(BuildContext context) {
    final cubit = context.read<LocaleCubit>();

    NeuBottomSheet.show<void>(
      context: context,
      builder: (sheetContext) {
        return BlocBuilder<LocaleCubit, Locale>(
          bloc: cubit,
          builder: (context, currentLocale) {
            final palette = context.read<ThemeCubit>().state.palette;
            return SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SheetDragHandle(),
                  SizedBox(height: 20.h),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    child: Text(
                      AppLocalizations.of(context).language_title,
                      style: AppTextStyles.manrope(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.bold,
                        color: palette.textDark,
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    child: Text(
                      AppLocalizations.of(context).language_choose,
                      style: AppTextStyles.manrope(
                        fontSize: 14.sp,
                        color: palette.textDark.withValues(alpha: .6),
                      ),
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Flexible(
                    child: ListView(
                      shrinkWrap: true,
                      children: appLocales.map((locale) {
                        return ListTile(
                          title: Text(
                            _localeLabel(locale.languageCode),
                            style: AppTextStyles.manrope(
                              color: palette.textDark,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          trailing:
                              locale.languageCode == currentLocale.languageCode
                              ? Icon(
                                  Icons.check_circle_rounded,
                                  color: palette.accent,
                                )
                              : null,
                          onTap: () async {
                            await cubit.setLocale(locale);
                            if (sheetContext.mounted) {
                              sheetContext.pop();
                            }
                          },
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
