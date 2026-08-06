import 'package:expense_flow_app/core/di/injection_container.dart';
import 'package:expense_flow_app/core/error/error_formatter.dart';
import 'package:expense_flow_app/core/theme/app_text_styles.dart';
import 'package:expense_flow_app/core/theme/neumorphic_styles.dart';
import 'package:expense_flow_app/core/theme/theme_cubit.dart';
import 'package:expense_flow_app/core/widgets/neu_snack_bar.dart';
import 'package:expense_flow_app/features/onboarding/presentation/widgets/cta_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../domain/usecases/acknowledge_disclaimer_usecase.dart';

/// One-time AI safety disclaimer shown on first launch.
///
/// After the user acknowledges, the acknowledgement is persisted via
/// [AcknowledgeDisclaimerUseCase] and the user is routed to onboarding.
class AiDisclaimerScreen extends StatefulWidget {
  const AiDisclaimerScreen({super.key});

  @override
  State<AiDisclaimerScreen> createState() => _AiDisclaimerScreenState();
}

class _AiDisclaimerScreenState extends State<AiDisclaimerScreen> {
  bool _acknowledging = false;

  Future<void> _acknowledge() async {
    if (_acknowledging) return;
    setState(() => _acknowledging = true);

    try {
      await sl<AcknowledgeDisclaimerUseCase>().call();
    } catch (e) {
      if (!mounted) return;
      setState(() => _acknowledging = false);
      NeuSnackBar.show(
        context: context,
        message: friendlyError(
          e,
          fallback:
              'Could not save your choice. '
              'Please try again.',
        ),
        type: NeuSnackBarType.error,
      );
      return;
    }

    if (!mounted) return;
    context.go('/onboarding');
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.watch<ThemeCubit>().state.palette;

    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 40.h),
              Container(
                    width: 88.w,
                    height: 88.w,
                    alignment: Alignment.center,
                    decoration: NeuBox.raised(
                      palette,
                      radius: 36.r,
                    ).copyWith(color: palette.accent),
                    child: Icon(
                      Icons.shield_outlined,
                      size: 46.w,
                      color: palette.onAccent,
                    ),
                  )
                  .animate()
                  .fadeIn(duration: 400.ms, curve: Curves.easeOut)
                  .scale(
                    begin: const Offset(0.7, 0.7),
                    end: const Offset(1, 1),
                    curve: Curves.easeOutBack,
                  ),
              SizedBox(height: 28.h),
              Text(
                    'AI Assistant Disclaimer',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.manrope(
                      fontSize: 22.sp,
                      fontWeight: FontWeight.w800,
                      color: palette.textDark,
                    ),
                  )
                  .animate(delay: 120.ms)
                  .fadeIn(duration: 300.ms, curve: Curves.easeOut)
                  .slideY(begin: 0.06, end: 0, curve: Curves.easeOutCubic),
              SizedBox(height: 12.h),
              Expanded(
                child: SingleChildScrollView(
                  child: Text(
                    'The AI assistant helps you understand your spending. It is '
                    'provided for informational purposes only and is not a '
                    'substitute for professional advice.\n\n'
                    'The assistant does not provide investment, tax, loan, or '
                    'medical advice. Never rely on it for financial or health '
                    'decisions. Always consult a qualified professional for '
                    'personal matters.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.manrope(
                      fontSize: 13.sp,
                      height: 1.6,
                      color: palette.textMuted,
                    ),
                  ).animate(delay: 200.ms).fadeIn(duration: 300.ms, curve: Curves.easeOut),
                ),
              ),
              SizedBox(height: 16.h),
              CtaButton(
                    label: 'I Understand',
                    isLast: true,
                    onTap: _acknowledge,
                  )
                  .animate(delay: 300.ms)
                  .fadeIn(duration: 300.ms, curve: Curves.easeOut)
                  .slideY(begin: 0.06, end: 0, curve: Curves.easeOutCubic),
              SizedBox(height: 24.h),
            ],
          ),
        ),
      ),
    );
  }
}
