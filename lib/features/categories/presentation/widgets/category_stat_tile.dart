import 'package:expense_flow_app/core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/neumorphic_styles.dart';
import '../../../../core/theme/theme_cubit.dart';
import '../../../../l10n/app_localizations.dart';

class CategoryStatTile extends StatelessWidget {
  final String emoji;
  final String label;
  final double spent;
  final double budget;
  final Color progressColor;
  final VoidCallback? onTap;
  final String currencySymbol;

  const CategoryStatTile({
    super.key,
    required this.emoji,
    required this.label,
    required this.spent,
    required this.budget,
    required this.progressColor,
    this.onTap,
    required this.currencySymbol,
  });

  double get _percent => budget <= 0 ? 0 : (spent / budget).clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    final palette = context.watch<ThemeCubit>().state.palette;
    final l10n = AppLocalizations.of(context);
    final percentLabel = (_percent * 100).round();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(16.w),
        decoration: NeuBox.raised(palette, radius: 20.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(emoji, style: TextStyle(fontSize: 18.sp)),
                    SizedBox(width: 8.w),
                    Text(
                      label,
                      style: AppTextStyles.manrope(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w600,
                        color: palette.textDark,
                      ),
                    ),
                  ],
                ),
                Text(
                  "$percentLabel%",
                  style: AppTextStyles.manrope(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: palette.textDark,
                  ),
                ),
              ],
            ),
            SizedBox(height: 5.h),
            ClipRRect(
              borderRadius: BorderRadius.circular(8.r),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Stack(
                    children: [
                      Container(
                        height: 8.h,
                        width: constraints.maxWidth,
                        color: palette.textDark.withValues(alpha: .1),
                      ),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeOut,
                        height: 8.h,
                        width: constraints.maxWidth * _percent,
                        color: progressColor,
                      ),
                    ],
                  );
                },
              ),
            ),
            SizedBox(height: 5.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.budget_spentAmount(
                    "$currencySymbol${spent.toStringAsFixed(0)}",
                  ),
                  style: AppTextStyles.manrope(
                    fontSize: 12.sp,
                    color: palette.textDark.withValues(alpha: .5),
                  ),
                ),
                Text(
                  l10n.budget_ofAmount(
                    "$currencySymbol${budget.toStringAsFixed(0)}",
                  ),
                  style: AppTextStyles.manrope(
                    fontSize: 12.sp,
                    color: palette.textDark.withValues(alpha: .5),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
