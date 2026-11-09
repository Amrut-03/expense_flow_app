import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/payment_methods.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/neumorphic_styles.dart';
import '../../../../core/theme/theme_cubit.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../currency/presentation/cubit/currency_cubit.dart';
import '../../../currency/presentation/util/currency_formatter.dart';
import '../../domain/services/payment_method_breakdown.dart';

/// This month's spend split by payment method, with the UPI/card vs cash
/// trend over the last six months.
class PaymentMethodCard extends StatelessWidget {
  const PaymentMethodCard({super.key, required this.breakdown});

  final PaymentMethodBreakdown breakdown;

  static Color colorFor(NeuPalette palette, String method) {
    switch (method) {
      case 'UPI':
        return palette.accent;
      case 'Card':
        return const Color(0xFF4C7BF4);
      case 'Cash':
        return palette.success;
      case 'Bank Transfer':
        return const Color(0xFF8E6CEF);
      default:
        return palette.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.watch<ThemeCubit>().state.palette;
    final currency = context.watch<CurrencyCubit>();
    final l10n = AppLocalizations.of(context);

    if (breakdown.isEmpty) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(20.h),
        decoration: NeuBox.raised(palette, radius: 16.r),
        child: Text(
          l10n.insights_noSpendThisMonth,
          style: AppTextStyles.manrope(
            fontSize: 13.sp,
            color: palette.textMuted,
          ),
        ),
      );
    }

    final digital = breakdown.digitalShare;
    final change = breakdown.digitalShareChange;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.h),
      decoration: NeuBox.raised(palette, radius: 16.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6.r),
            child: SizedBox(
              height: 12.h,
              child: Row(
                children: [
                  for (final m in breakdown.methods)
                    if (m.share > 0)
                      Expanded(
                        flex: (m.share * 1000).round().clamp(1, 1000),
                        child: Container(color: colorFor(palette, m.method)),
                      ),
                ],
              ),
            ),
          ),
          SizedBox(height: 14.h),
          for (final m in breakdown.methods)
            Padding(
              padding: EdgeInsets.only(bottom: 8.h),
              child: Row(
                children: [
                  Container(
                    width: 10.w,
                    height: 10.w,
                    decoration: BoxDecoration(
                      color: colorFor(palette, m.method),
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    '${PaymentMethods.emojis[m.method] ?? '💸'} '
                    '${PaymentMethods.localizedLabel(l10n, m.method)}',
                    style: AppTextStyles.manrope(
                      fontSize: 13.sp,
                      color: palette.textDark,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    CurrencyFormatter.format(
                      cubit: currency,
                      amountInInr: m.amount,
                    ),
                    style: AppTextStyles.manrope(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                      color: palette.textDark,
                    ),
                  ),
                  SizedBox(
                    width: 48.w,
                    child: Text(
                      '${(m.share * 100).round()}%',
                      textAlign: TextAlign.end,
                      style: AppTextStyles.manrope(
                        fontSize: 12.sp,
                        color: palette.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (digital != null) ...[
            SizedBox(height: 6.h),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.insights_digitalShare(
                          (digital * 100).round().toString(),
                        ),
                        style: AppTextStyles.manrope(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                          color: palette.textDark,
                        ),
                      ),
                      if (change != null && change.abs() >= 1)
                        Text(
                          change > 0
                              ? l10n.insights_digitalUp(
                                  change.round().toString(),
                                )
                              : l10n.insights_digitalDown(
                                  (-change).round().toString(),
                                ),
                          style: AppTextStyles.manrope(
                            fontSize: 11.sp,
                            color: palette.textMuted,
                          ),
                        ),
                    ],
                  ),
                ),
                _Trend(values: breakdown.digitalShareTrend, palette: palette),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Six tiny bars: digital share per month, oldest first.
class _Trend extends StatelessWidget {
  const _Trend({required this.values, required this.palette});

  final List<double?> values;
  final NeuPalette palette;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 28.h,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < values.length; i++)
            Container(
              width: 6.w,
              margin: EdgeInsets.only(left: 3.w),
              height: 28.h * ((values[i] ?? 0).clamp(0.06, 1.0)),
              decoration: BoxDecoration(
                color: values[i] == null
                    ? palette.textMuted.withValues(alpha: .2)
                    : palette.accent.withValues(
                        alpha: i == values.length - 1 ? 1 : .45,
                      ),
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
        ],
      ),
    );
  }
}
