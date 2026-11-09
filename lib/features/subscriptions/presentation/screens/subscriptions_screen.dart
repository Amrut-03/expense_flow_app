import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/expense_category.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/neumorphic_styles.dart';
import '../../../../core/theme/theme_cubit.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/neu_app_bar.dart';
import '../../../../core/widgets/neu_loading.dart';
import '../../../../core/widgets/neu_snack_bar.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../currency/presentation/cubit/currency_cubit.dart';
import '../../../currency/presentation/util/currency_formatter.dart';
import '../../../recurring/presentation/recurrence_labels.dart';
import '../../domain/entities/detected_subscription.dart';
import '../cubit/subscriptions_cubit.dart';

class SubscriptionsScreen extends StatelessWidget {
  const SubscriptionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = context.watch<ThemeCubit>().state.palette;
    final currency = context.watch<CurrencyCubit>();
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(24.w, 10.h, 24.w, 0),
              child: NeuAppBar(
                title: l10n.subscriptions_title,
                onBack: () => context.pop(),
              ),
            ),
            Expanded(
              child: BlocBuilder<SubscriptionsCubit, SubscriptionsState>(
                builder: (context, state) {
                  if (state.loading) {
                    return const Center(child: NeuLoading());
                  }
                  if (state.items.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24.w),
                        child: EmptyStateWidget(
                          icon: Text('📺', style: TextStyle(fontSize: 40.sp)),
                          title: l10n.subscriptions_emptyTitle,
                          subtitle: l10n.subscriptions_emptyHint,
                        ),
                      ),
                    );
                  }

                  return ListView(
                    padding: EdgeInsets.fromLTRB(24.w, 20.h, 24.w, 24.h),
                    children: [
                      Container(
                        padding: EdgeInsets.all(20.r),
                        decoration: NeuBox.raised(palette, radius: 18.r),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.subscriptions_monthlyTotal,
                              style: AppTextStyles.manrope(
                                fontSize: 12.sp,
                                color: palette.textMuted,
                              ),
                            ),
                            SizedBox(height: 8.h),
                            Text(
                              CurrencyFormatter.format(
                                cubit: currency,
                                amountInInr: state.monthlyTotal,
                              ),
                              style: AppTextStyles.manrope(
                                fontSize: 26.sp,
                                fontWeight: FontWeight.bold,
                                color: palette.textDark,
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              l10n.subscriptions_yearlyTotal(
                                CurrencyFormatter.format(
                                  cubit: currency,
                                  amountInInr: state.monthlyTotal * 12,
                                ),
                              ),
                              style: AppTextStyles.manrope(
                                fontSize: 12.sp,
                                color: palette.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 16.h),
                      for (final sub in state.items) ...[
                        _SubscriptionTile(sub: sub),
                        SizedBox(height: 12.h),
                      ],
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SubscriptionTile extends StatelessWidget {
  const _SubscriptionTile({required this.sub});

  final DetectedSubscription sub;

  @override
  Widget build(BuildContext context) {
    final palette = context.watch<ThemeCubit>().state.palette;
    final currency = context.watch<CurrencyCubit>();
    final l10n = AppLocalizations.of(context);
    final category = ExpenseCategories.byId(sub.categoryId);
    String money(double inr) =>
        CurrencyFormatter.format(cubit: currency, amountInInr: inr);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      decoration: NeuBox.raised(palette, radius: 20.r),
      child: Row(
        children: [
          Container(
            width: 44.w,
            height: 44.w,
            alignment: Alignment.center,
            decoration: NeuBox.raised(palette, radius: 12.r),
            child: Text(category.emoji, style: TextStyle(fontSize: 18.sp)),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sub.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.manrope(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: palette.textDark,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  '${money(sub.amount)} · ${sub.frequency.label(l10n)}',
                  style: AppTextStyles.manrope(
                    fontSize: 12.sp,
                    color: palette.textMuted,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  l10n.subscriptions_nextCharge(
                    DateFormat.yMMMd(l10n.localeName).format(sub.nextExpected),
                    money(sub.annualCost),
                  ),
                  style: AppTextStyles.manrope(
                    fontSize: 12.sp,
                    color: palette.textMuted,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 8.w),
          if (sub.isTracked)
            Text(
              l10n.subscriptions_tracked,
              style: AppTextStyles.manrope(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: palette.success,
              ),
            )
          else
            TextButton(
              onPressed: () async {
                await context.read<SubscriptionsCubit>().startTracking(sub);
                if (context.mounted) {
                  NeuSnackBar.show(
                    context: context,
                    message: l10n.subscriptions_trackedMessage(sub.name),
                    type: NeuSnackBarType.success,
                  );
                }
              },
              child: Text(
                l10n.subscriptions_track,
                style: AppTextStyles.manrope(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  color: palette.accent,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
