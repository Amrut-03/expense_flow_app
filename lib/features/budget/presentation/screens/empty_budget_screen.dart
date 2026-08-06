import 'package:expense_flow_app/core/theme/app_text_styles.dart';
import 'package:expense_flow_app/core/widgets/neu_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/neumorphic_styles.dart';
import '../../../../core/theme/theme_cubit.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/neu_button.dart';
import '../../../../l10n/app_localizations.dart';

/// Shown the first time the user opens Budget and has no budgets set yet.
/// "Create your budget" pushes the editing screen; "Skip for now" pops
/// back so the user isn't forced into setup.
class BudgetEmptyStateScreen extends StatelessWidget {
  final VoidCallback? onPop;

  const BudgetEmptyStateScreen({super.key, this.onPop});

  @override
  Widget build(BuildContext context) {
    final palette = context.watch<ThemeCubit>().state.palette;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            children: [
              NeuAppBar(
                title: l10n.budget_title,
                onBack: onPop ?? () => context.pop(),
              ),
              Expanded(
                child: Center(
                  child:
                      EmptyStateWidget(
                            icon:
                                Container(
                                      width: 88.w,
                                      height: 88.w,
                                      decoration: BoxDecoration(
                                        color: palette.accent.withValues(
                                          alpha: .5,
                                        ),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.account_balance_wallet_outlined,
                                        size: 36.h,
                                        color: palette.background,
                                      ),
                                    )
                                    .animate()
                                    .fadeIn(
                                      duration: 400.ms,
                                      curve: Curves.easeOut,
                                    )
                                    .scale(
                                      begin: const Offset(0.7, 0.7),
                                      end: const Offset(1, 1),
                                      curve: Curves.easeOutBack,
                                    ),
                            title: l10n.budget_setFirstBudget,
                            subtitle: l10n.budget_setFirstBudgetSubtitle,
                            action: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                      width: double.infinity,
                                      child: NeuButton(
                                        label: l10n.budget_createYourBudget,
                                        onTap: () =>
                                            context.push('/budget/edit'),
                                        bgColor: palette.accent,
                                        icon: Icons.add,
                                      ),
                                    )
                                    .animate(delay: 150.ms)
                                    .fadeIn(
                                      duration: 300.ms,
                                      curve: Curves.easeOut,
                                    )
                                    .slideY(
                                      begin: 0.08,
                                      end: 0,
                                      curve: Curves.easeOutCubic,
                                    ),
                                TextButton(
                                      onPressed: onPop ?? () => context.pop(),
                                      child: Text(
                                        l10n.budget_skipForNow,
                                        style: AppTextStyles.manrope(
                                          fontSize: 14.sp,
                                          color: palette.textDark.withValues(
                                            alpha: .6,
                                          ),
                                        ),
                                      ),
                                    )
                                    .animate(delay: 220.ms)
                                    .fadeIn(
                                      duration: 300.ms,
                                      curve: Curves.easeOut,
                                    ),
                              ],
                            ),
                          )
                          .animate()
                          .fadeIn(duration: 300.ms, curve: Curves.easeOut)
                          .slideY(
                            begin: 0.1,
                            end: 0,
                            curve: Curves.easeOutCubic,
                          ),
                ),
              ),
              _InfoRow(
                    icon: Icons.notifications_none,
                    text: l10n.budget_notifiedBeforeOverspend,
                    palette: palette,
                  )
                  .animate(delay: 320.ms)
                  .fadeIn(duration: 260.ms, curve: Curves.easeOut),
              SizedBox(height: 10.h),
              _InfoRow(
                    icon: Icons.bar_chart,
                    text: l10n.budget_spendingTrends,
                    palette: palette,
                  )
                  .animate(delay: 380.ms)
                  .fadeIn(duration: 260.ms, curve: Curves.easeOut),
              SizedBox(height: 24.h),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.text,
    required this.palette,
  });

  final IconData icon;
  final String text;
  final dynamic palette;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: NeuBox.raised(
        palette,
        radius: 12.r,
        bgColor: palette.background,
      ),
      child: Row(
        children: [
          Icon(icon, size: 16.h, color: palette.textDark.withValues(alpha: .5)),
          SizedBox(width: 10.w),
          Text(
            text,
            style: AppTextStyles.manrope(
              fontSize: 12.sp,
              color: palette.textDark.withValues(alpha: .6),
            ),
          ),
        ],
      ),
    );
  }
}
