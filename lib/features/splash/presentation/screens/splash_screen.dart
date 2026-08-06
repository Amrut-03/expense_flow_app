import 'dart:math' as math;

import 'package:expense_flow_app/core/di/injection_container.dart';
import 'package:expense_flow_app/core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';

import '../../../../core/theme/neumorphic_styles.dart';
import '../../../../core/theme/theme_cubit.dart';
import '../../../ai/domain/usecases/should_show_disclaimer_usecase.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../auth/presentation/bloc/auth_state.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  static const _settingsBoxName = 'settings';
  static const _onboardingSeenKey = 'has_seen_onboarding';

  @override
  void initState() {
    super.initState();
    _navigateNext();
  }

  Future<void> _navigateNext() async {
    await Future.delayed(const Duration(milliseconds: 1800));
    if (!mounted) return;

    final box = await Hive.openBox(_settingsBoxName);
    final hasSeenOnboarding =
        box.get(_onboardingSeenKey, defaultValue: false) as bool;

    if (!mounted) return;

    final shouldShowDisclaimer = await sl<ShouldShowDisclaimerUseCase>().call();
    if (!mounted) return;

    if (shouldShowDisclaimer) {
      context.go('/ai-disclaimer');
      return;
    }

    if (hasSeenOnboarding) {
      context.read<AuthBloc>().add(CheckAuthStatus());
    } else {
      context.go('/onboarding');
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.watch<ThemeCubit>().state.palette;

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is Authenticated) {
          context.go("/dashboard");
        } else {
          context.go("/login");
        }
      },
      child: Scaffold(
        backgroundColor: palette.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                    width: 84,
                    height: 84,
                    decoration: NeuBox.raised(
                      palette,
                      radius: 24,
                    ).copyWith(color: palette.accent),
                    child: Icon(
                      Icons.credit_card_rounded,
                      color: palette.onAccent,
                      size: 34,
                    ),
                  )
                  .animate()
                  .fadeIn(duration: 500.ms)
                  .scale(
                    begin: const Offset(0.7, 0.7),
                    curve: Curves.easeOutBack,
                  ),

              const SizedBox(height: 20),

              Text(
                    'ExpenseFlow',
                    style: AppTextStyles.manrope(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: palette.textDark,
                    ),
                  )
                  .animate()
                  .fadeIn(delay: 300.ms, duration: 500.ms)
                  .slideY(begin: 0.2, end: 0, curve: Curves.easeOut),

              const SizedBox(height: 4),

              Text(
                'Track. Budget. Breathe.',
                style: AppTextStyles.manrope(
                  fontSize: 12,
                  color: palette.textMuted,
                ),
              ).animate().fadeIn(delay: 500.ms, duration: 500.ms),

              const SizedBox(height: 26),

              _LoadingDots().animate().fadeIn(delay: 700.ms),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoadingDots extends StatefulWidget {
  @override
  State<_LoadingDots> createState() => _LoadingDotsState();
}

class _LoadingDotsState extends State<_LoadingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.watch<ThemeCubit>().state.palette;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            // Each dot trails the previous by a third of a cycle so the
            // highlight flows smoothly left-to-right instead of jumping.
            final phase = (t - i / 3) % 1.0;
            final intensity = 0.5 - 0.5 * math.cos(phase * 2 * math.pi);
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Color.lerp(
                  palette.shadowDark,
                  palette.accent,
                  intensity,
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
