import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/neumorphic_styles.dart';
import '../../../../core/theme/theme_cubit.dart';
import '../../../../core/widgets/neu_button.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/repositories/app_lock_repository.dart';
import '../cubit/app_lock_cubit.dart';

/// Sits above the router (via `MaterialApp.router(builder:)`) and covers the
/// whole app with a lock screen while [AppLockCubit] is locked.
class AppLockGate extends StatefulWidget {
  const AppLockGate({super.key, required this.child});

  final Widget child;

  @override
  State<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends State<AppLockGate> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState lifecycle) {
    final cubit = context.read<AppLockCubit>();
    switch (lifecycle) {
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
        cubit.onBackgrounded();
      case AppLifecycleState.resumed:
        cubit.onForegrounded();
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppLockCubit, AppLockState>(
      buildWhen: (a, b) => a.locked != b.locked,
      builder: (context, state) {
        return Stack(
          children: [
            // Keep the app mounted so navigation state survives a lock.
            ExcludeSemantics(excluding: state.locked, child: widget.child),
            if (state.locked) const Positioned.fill(child: _LockScreen()),
          ],
        );
      },
    );
  }
}

class _LockScreen extends StatefulWidget {
  const _LockScreen();

  @override
  State<_LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<_LockScreen> {
  @override
  void initState() {
    super.initState();
    // Prompt immediately; the button is there for retries.
    WidgetsBinding.instance.addPostFrameCallback((_) => _unlock());
  }

  void _unlock() {
    if (!mounted) return;
    context.read<AppLockCubit>().unlock(
      reason: AppLocalizations.of(context).appLock_reason,
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.watch<ThemeCubit>().state.palette;
    final l10n = AppLocalizations.of(context);

    return Material(
      color: palette.background,
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 32.w),
          child: BlocBuilder<AppLockCubit, AppLockState>(
            builder: (context, state) {
              final failure = switch (state.lastFailure) {
                AppLockAuthResult.lockedOut => l10n.appLock_lockedOut,
                AppLockAuthResult.failed => l10n.appLock_failed,
                _ => null,
              };

              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 88.w,
                    height: 88.w,
                    alignment: Alignment.center,
                    decoration: NeuBox.raised(palette, radius: 44.w),
                    child: Text('🔒', style: TextStyle(fontSize: 36.sp)),
                  ),
                  SizedBox(height: 28.h),
                  Text(
                    l10n.appLock_lockedTitle,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.manrope(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                      color: palette.textDark,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    l10n.appLock_lockedSubtitle,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.manrope(
                      fontSize: 14.sp,
                      color: palette.textMuted,
                    ),
                  ),
                  if (failure != null) ...[
                    SizedBox(height: 16.h),
                    Text(
                      failure,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.manrope(
                        fontSize: 13.sp,
                        color: palette.danger,
                      ),
                    ),
                  ],
                  SizedBox(height: 32.h),
                  NeuButton(
                    label: l10n.appLock_unlock,
                    icon: Icons.fingerprint,
                    loading: state.authenticating,
                    onTap: state.authenticating ? null : _unlock,
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
