import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/neumorphic_styles.dart';
import '../../../../core/theme/theme_cubit.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../currency/presentation/cubit/currency_cubit.dart';
import '../../../currency/presentation/util/currency_formatter.dart';
import '../../domain/usecases/get_budget_insights_usecase.dart';
import '../bloc/budget_insights_cubit.dart';

/// "Safe to spend today": the sum of every budget's remaining daily
/// allowance after upcoming recurring bills. Prompts to set a budget when
/// there is nothing to compute from.
class SafeToSpendCard extends StatelessWidget {
  const SafeToSpendCard({super.key, this.onSetBudget});

  final VoidCallback? onSetBudget;

  @override
  Widget build(BuildContext context) {
    final palette = context.watch<ThemeCubit>().state.palette;
    final currency = context.watch<CurrencyCubit>();
    final l10n = AppLocalizations.of(context);

    return BlocBuilder<BudgetInsightsCubit, BudgetInsights>(
      builder: (context, insights) {
        final safe = insights.safeToSpend;
        String money(double inr) =>
            CurrencyFormatter.format(cubit: currency, amountInInr: inr);

        if (!safe.hasBudgets) {
          return GestureDetector(
            onTap: onSetBudget,
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.all(16.r),
              decoration: NeuBox.raised(palette, radius: 16.r),
              child: Row(
                children: [
                  Text('🧭', style: TextStyle(fontSize: 22.sp)),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(
                      l10n.safeToSpend_setBudgetHint,
                      style: AppTextStyles.manrope(
                        fontSize: 13.sp,
                        color: palette.textDark,
                      ),
                    ),
                  ),
                  Icon(Icons.chevron_right, color: palette.textMuted),
                ],
              ),
            ),
          );
        }

        final subtitle = safe.overBudgetCount > 0
            ? l10n.safeToSpend_overBudget(safe.overBudgetCount)
            : safe.reservedForBills > 0
            ? l10n.safeToSpend_afterBills(money(safe.reservedForBills))
            : l10n.safeToSpend_basedOnBudgets;

        return Container(
          width: double.infinity,
          padding: EdgeInsets.all(20.h),
          decoration: NeuBox.raised(palette, radius: 16.r),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.safeToSpend_title,
                style: AppTextStyles.manrope(
                  fontSize: 12.sp,
                  color: palette.textDark.withValues(alpha: .5),
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                money(safe.today),
                style: AppTextStyles.manrope(
                  fontSize: 26.sp,
                  fontWeight: FontWeight.bold,
                  color: safe.today > 0 ? palette.success : palette.danger,
                ),
              ),
              SizedBox(height: 6.h),
              Text(
                subtitle,
                style: AppTextStyles.manrope(
                  fontSize: 12.sp,
                  color: safe.overBudgetCount > 0
                      ? palette.danger
                      : palette.textMuted,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
