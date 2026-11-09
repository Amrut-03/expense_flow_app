import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/neumorphic_styles.dart';
import '../../../../core/theme/theme_cubit.dart';
import '../../../../core/widgets/neu_bottom_sheet.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/voice_expense_draft.dart';
import '../../domain/services/speech_recognizer.dart';
import '../cubit/voice_entry_cubit.dart';

/// "Speak your expense" sheet. Pops with the understood draft.
abstract final class VoiceEntrySheet {
  static Future<VoiceExpenseDraft?> show(
    BuildContext context, {
    required VoiceEntryCubit Function() create,
  }) {
    return NeuBottomSheet.show<VoiceExpenseDraft>(
      context: context,
      isScrollControlled: true,
      builder: (_) => BlocProvider(
        create: (_) => create()..start(),
        child: const _VoiceEntryView(),
      ),
    );
  }
}

class _VoiceEntryView extends StatelessWidget {
  const _VoiceEntryView();

  static const _languageNames = {
    'en-IN': 'English',
    'hi-IN': 'हिंदी',
    'mr-IN': 'मराठी',
  };

  String _failureText(AppLocalizations l10n, VoiceEntryState s) =>
      switch (s.failure) {
        SpeechFailure.permissionDenied => l10n.voice_permissionDenied,
        SpeechFailure.unavailable => l10n.voice_unavailable,
        SpeechFailure.languageUnavailableOffline =>
          s.onDevice ? l10n.voice_offlineUnavailable : l10n.voice_needsInternet,
        SpeechFailure.noMatch => l10n.voice_noMatch,
        _ => l10n.voice_failed,
      };

  @override
  Widget build(BuildContext context) {
    final palette = context.watch<ThemeCubit>().state.palette;
    final l10n = AppLocalizations.of(context);

    return BlocConsumer<VoiceEntryCubit, VoiceEntryState>(
      listenWhen: (p, s) => s.phase == VoicePhase.done && s.draft != null,
      listener: (context, s) => Navigator.of(context).pop(s.draft),
      builder: (context, s) {
        final cubit = context.read<VoiceEntryCubit>();
        final listening = s.phase == VoicePhase.listening;
        final busy = s.phase == VoicePhase.processing;

        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(24.w, 20.h, 24.w, 16.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.voice_title,
                  style: AppTextStyles.manrope(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: palette.textDark,
                  ),
                ),
                SizedBox(height: 12.h),
                Wrap(
                  spacing: 8.w,
                  children: [
                    for (final locale in VoiceEntryCubit.locales)
                      ChoiceChip(
                        label: Text(_languageNames[locale]!),
                        selected: s.localeId == locale,
                        selectedColor: palette.accent,
                        labelStyle: AppTextStyles.manrope(
                          fontSize: 12.sp,
                          color: s.localeId == locale
                              ? palette.background
                              : palette.textDark,
                        ),
                        backgroundColor: palette.background,
                        onSelected: busy
                            ? null
                            : (_) => cubit.selectLocale(locale),
                      ),
                  ],
                ),
                SizedBox(height: 20.h),
                GestureDetector(
                  onTap: busy
                      ? null
                      : listening
                      ? cubit.stop
                      : cubit.start,
                  child: _MicButton(
                    palette: palette,
                    listening: listening,
                    busy: busy,
                  ),
                ),
                SizedBox(height: 16.h),
                ConstrainedBox(
                  constraints: BoxConstraints(minHeight: 44.h),
                  child: Text(
                    switch (s.phase) {
                      VoicePhase.failed => _failureText(l10n, s),
                      VoicePhase.processing => s.partial,
                      _ when s.partial.isNotEmpty => s.partial,
                      VoicePhase.listening => l10n.voice_listening,
                      _ => l10n.voice_tapToSpeak,
                    },
                    textAlign: TextAlign.center,
                    style: AppTextStyles.manrope(
                      fontSize: 15.sp,
                      fontWeight: s.partial.isNotEmpty
                          ? FontWeight.w600
                          : FontWeight.w400,
                      color: s.phase == VoicePhase.failed
                          ? palette.danger
                          : palette.textDark,
                    ),
                  ),
                ),
                if (s.phase == VoicePhase.failed &&
                    s.failure == SpeechFailure.languageUnavailableOffline &&
                    s.onDevice) ...[
                  SizedBox(height: 8.h),
                  TextButton(
                    onPressed: cubit.retryOnline,
                    child: Text(
                      l10n.voice_useOnline,
                      style: AppTextStyles.manrope(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                        color: palette.accent,
                      ),
                    ),
                  ),
                ],
                SizedBox(height: 8.h),
                Text(
                  s.onDevice ? l10n.voice_examples : l10n.voice_onlineNote,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.manrope(
                    fontSize: 11.sp,
                    color: palette.textMuted,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MicButton extends StatelessWidget {
  const _MicButton({
    required this.palette,
    required this.listening,
    required this.busy,
  });

  final NeuPalette palette;
  final bool listening;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: listening ? 92.w : 80.w,
      height: listening ? 92.w : 80.w,
      decoration: NeuBox.raised(
        palette,
        radius: 46.w,
        bgColor: listening ? palette.accent : palette.background,
      ),
      alignment: Alignment.center,
      child: busy
          ? SizedBox(
              width: 28.w,
              height: 28.w,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: palette.accent,
              ),
            )
          : Icon(
              listening ? Icons.stop_rounded : Icons.mic_rounded,
              size: 36.sp,
              color: listening ? palette.background : palette.accent,
            ),
    );
  }
}
