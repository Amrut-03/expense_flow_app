import 'package:expense_flow_app/core/theme/app_text_styles.dart';
import 'package:expense_flow_app/core/theme/neumorphic_styles.dart';
import 'package:expense_flow_app/core/theme/theme_cubit.dart';
import 'package:expense_flow_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';

import '../widgets/cta_button.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, this.onFinished});

  final VoidCallback? onFinished;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingSlideData {
  final String title;
  final String subtitle;
  final IconData icon;
  final IconData accentIcon;

  const _OnboardingSlideData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentIcon,
  });
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const _slideCount = 3;
  static const _settingsBoxName = 'settings';
  static const _onboardingSeenKey = 'has_seen_onboarding';

  final PageController _controller = PageController();

  int _current = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _isLast => _current == _slideCount - 1;

  void _next() {
    if (_isLast) {
      _finish();
      return;
    }
    _controller.nextPage(
      duration: const Duration(milliseconds: 360),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _finish() async {
    if (widget.onFinished != null) {
      widget.onFinished!();
      return;
    }
    final box = await Hive.openBox(_settingsBoxName);
    await box.put(_onboardingSeenKey, true);
    if (!mounted) return;
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.watch<ThemeCubit>().state.palette;
    final l10n = AppLocalizations.of(context);

    final slides = [
      _OnboardingSlideData(
        title: l10n.onboarding_slide1Title,
        subtitle: l10n.onboarding_slide1Subtitle,
        icon: Icons.receipt_long_rounded,
        accentIcon: Icons.add_card_rounded,
      ),
      _OnboardingSlideData(
        title: l10n.onboarding_slide2Title,
        subtitle: l10n.onboarding_slide2Subtitle,
        icon: Icons.pie_chart_rounded,
        accentIcon: Icons.savings_rounded,
      ),
      _OnboardingSlideData(
        title: l10n.onboarding_slide3Title,
        subtitle: l10n.onboarding_slide3Subtitle,
        icon: Icons.auto_graph_rounded,
        accentIcon: Icons.insights_rounded,
      ),
    ];

    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 8.h, 12.w, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: !_isLast
                        ? GestureDetector(
                            key: const ValueKey('skip'),
                            onTap: _finish,
                            child: Padding(
                              padding: EdgeInsets.all(8.w),
                              child: Text(
                                AppLocalizations.of(context).onboarding_skip,
                                style: AppTextStyles.manrope(
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w600,
                                  color: palette.textMuted,
                                ),
                              ),
                            ),
                          )
                        : const SizedBox.shrink(key: ValueKey('no-skip')),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _slideCount,
                onPageChanged: (index) {
                  setState(() => _current = index);
                },
                itemBuilder: (context, index) {
                  return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(height: 24.h),
                          SizedBox(
                                width: 80.w,
                                height: 80.h,
                                child: Container(
                                  width: 132.w,
                                  height: 132.w,
                                  alignment: Alignment.center,
                                  decoration: NeuBox.raised(
                                    palette,
                                    radius: 36.r,
                                  ).copyWith(color: palette.accent),
                                  child: Icon(
                                    slides[index].icon,
                                    size: 54.w,
                                    color: palette.onAccent,
                                  ),
                                ),
                              )
                              .animate()
                              .fadeIn(duration: 600.ms)
                              .scale(
                                begin: const Offset(0.85, 0.85),
                                end: const Offset(1, 1),
                                curve: Curves.easeOutBack,
                                duration: 600.ms,
                              ),
                          SizedBox(height: 52.h),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 36.w),
                            child: Column(
                              children: [
                                Text(
                                  slides[index].title,
                                  textAlign: TextAlign.center,
                                  style: AppTextStyles.manrope(
                                    fontSize: 22.sp,
                                    fontWeight: FontWeight.w800,
                                    color: palette.textDark,
                                  ),
                                ),
                                SizedBox(height: 12.h),
                                Text(
                                  slides[index].subtitle,
                                  textAlign: TextAlign.center,
                                  style: AppTextStyles.manrope(
                                    fontSize: 12.sp,
                                    height: 1.5,
                                    color: palette.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 24.h),
                        ],
                      )
                      .animate()
                      .fadeIn(duration: 450.ms, curve: Curves.easeOut)
                      .slideY(begin: 0.12, end: 0, curve: Curves.easeOutCubic);
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_slideCount, (index) {
                final active = index == _current;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeOut,
                  margin: EdgeInsets.symmetric(horizontal: 2.w),
                  width: active ? 20.w : 8.w,
                  height: 8.w,
                  decoration: BoxDecoration(
                    color: active ? palette.accent : palette.shadowDark,
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                );
              }),
            ),
            SizedBox(height: 28.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: CtaButton(
                label: _isLast
                    ? l10n.onboarding_getStarted
                    : l10n.onboarding_next,
                isLast: _isLast,
                onTap: _next,
              ),
            ),
            SizedBox(height: 24.h),
          ],
        ),
      ),
    );
  }
}
