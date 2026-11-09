import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/neumorphic_styles.dart';
import '../../../../core/theme/theme_cubit.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/neu_app_bar.dart';
import '../../../../core/widgets/neu_loading.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../currency/presentation/cubit/currency_cubit.dart';
import '../../../currency/presentation/util/currency_formatter.dart';
import '../../domain/usecases/get_tax_summary_usecase.dart';
import '../cubit/tax_summary_cubit.dart';
import '../tax_labels.dart';

/// Year-end view of tax-tagged expenses, grouped by section, for filing.
class TaxSummaryScreen extends StatelessWidget {
  const TaxSummaryScreen({super.key, this.onExport});

  /// Shares the visible financial year's summary, when provided.
  final void Function(BuildContext context, TaxSummary summary)? onExport;

  @override
  Widget build(BuildContext context) {
    final palette = context.watch<ThemeCubit>().state.palette;
    final currency = context.watch<CurrencyCubit>();
    final l10n = AppLocalizations.of(context);
    String money(double inr) =>
        CurrencyFormatter.format(cubit: currency, amountInInr: inr);

    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        child: BlocBuilder<TaxSummaryCubit, TaxSummaryState>(
          builder: (context, state) {
            final summary = state.summary;
            final cubit = context.read<TaxSummaryCubit>();

            return Column(
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(24.w, 10.h, 24.w, 0),
                  child: NeuAppBar(
                    title: l10n.tax_summaryTitle,
                    onBack: () => context.pop(),
                    trailing:
                        onExport != null &&
                            summary != null &&
                            !summary.isEmpty
                        ? IconButton(
                            tooltip: l10n.export_share,
                            icon: Icon(
                              Icons.ios_share,
                              color: palette.textDark,
                              size: 20.sp,
                            ),
                            onPressed: () => onExport!(context, summary),
                          )
                        : null,
                  ),
                ),
                SizedBox(height: 12.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: Icon(Icons.chevron_left, color: palette.textDark),
                      onPressed: cubit.previousYear,
                    ),
                    Text(
                      state.year.label,
                      style: AppTextStyles.manrope(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w600,
                        color: palette.textDark,
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.chevron_right,
                        color: state.canGoNext
                            ? palette.textDark
                            : palette.textMuted.withValues(alpha: .3),
                      ),
                      onPressed: state.canGoNext ? cubit.nextYear : null,
                    ),
                  ],
                ),
                Expanded(
                  child: Builder(
                    builder: (context) {
                      if (state.loading && summary == null) {
                        return const Center(child: NeuLoading());
                      }
                      if (summary == null || summary.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 24.w),
                            child: EmptyStateWidget(
                              icon: Text(
                                '🧾',
                                style: TextStyle(fontSize: 40.sp),
                              ),
                              title: l10n.tax_emptyTitle,
                              subtitle: l10n.tax_emptyHint,
                            ),
                          ),
                        );
                      }

                      return ListView(
                        padding: EdgeInsets.fromLTRB(24.w, 8.h, 24.w, 24.h),
                        children: [
                          Container(
                            padding: EdgeInsets.all(20.r),
                            decoration: NeuBox.raised(palette, radius: 18.r),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.tax_totalClaimable,
                                  style: AppTextStyles.manrope(
                                    fontSize: 12.sp,
                                    color: palette.textMuted,
                                  ),
                                ),
                                SizedBox(height: 8.h),
                                Text(
                                  money(summary.totalClaimable),
                                  style: AppTextStyles.manrope(
                                    fontSize: 26.sp,
                                    fontWeight: FontWeight.bold,
                                    color: palette.textDark,
                                  ),
                                ),
                                SizedBox(height: 8.h),
                                Text(
                                  l10n.tax_oldRegimeNote,
                                  style: AppTextStyles.manrope(
                                    fontSize: 11.sp,
                                    color: palette.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 16.h),
                          for (final section in summary.sections) ...[
                            _SectionCard(total: section, money: money),
                            SizedBox(height: 12.h),
                          ],
                        ],
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SectionCard extends StatefulWidget {
  const _SectionCard({required this.total, required this.money});

  final TaxSectionTotal total;
  final String Function(double inr) money;

  @override
  State<_SectionCard> createState() => _SectionCardState();
}

class _SectionCardState extends State<_SectionCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final palette = context.watch<ThemeCubit>().state.palette;
    final l10n = AppLocalizations.of(context);
    final total = widget.total;
    final section = total.section;
    final cap = section.cap;
    final money = widget.money;
    final dateFormat = DateFormat.MMMd(l10n.localeName);

    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: NeuBox.raised(palette, radius: 20.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Row(
              children: [
                Container(
                  width: 44.w,
                  height: 44.w,
                  alignment: Alignment.center,
                  decoration: NeuBox.raised(palette, radius: 12.r),
                  child: Text(section.emoji, style: TextStyle(fontSize: 18.sp)),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        section.code,
                        style: AppTextStyles.manrope(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: palette.textDark,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        section.description(l10n),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.manrope(
                          fontSize: 11.sp,
                          color: palette.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 8.w),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      money(total.total),
                      style: AppTextStyles.manrope(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                        color: palette.textDark,
                      ),
                    ),
                    Text(
                      l10n.tax_expenseCount(total.expenses.length),
                      style: AppTextStyles.manrope(
                        fontSize: 11.sp,
                        color: palette.textMuted,
                      ),
                    ),
                  ],
                ),
                Icon(
                  _expanded ? Icons.expand_less : Icons.expand_more,
                  color: palette.textMuted,
                ),
              ],
            ),
          ),
          SizedBox(height: 12.h),
          if (cap != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(8.r),
              child: LinearProgressIndicator(
                value: (total.total / cap).clamp(0, 1).toDouble(),
                minHeight: 8.h,
                backgroundColor: palette.textMuted.withValues(alpha: .15),
                valueColor: AlwaysStoppedAnimation(
                  total.total >= cap ? palette.success : palette.accent,
                ),
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              l10n.tax_capUsed(money(total.claimable), money(cap)),
              style: AppTextStyles.manrope(
                fontSize: 12.sp,
                color: palette.textMuted,
              ),
            ),
            if ((total.remainingCap ?? 0) > 0)
              Text(
                l10n.tax_capRemaining(money(total.remainingCap!)),
                style: AppTextStyles.manrope(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: palette.accent,
                ),
              ),
          ] else
            Text(
              l10n.tax_noCap,
              style: AppTextStyles.manrope(
                fontSize: 12.sp,
                color: palette.textMuted,
              ),
            ),
          if (_expanded) ...[
            SizedBox(height: 8.h),
            Divider(color: palette.textMuted.withValues(alpha: .2)),
            for (final e in total.expenses)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 6.h),
                child: Row(
                  children: [
                    SizedBox(
                      width: 56.w,
                      child: Text(
                        dateFormat.format(e.date),
                        style: AppTextStyles.manrope(
                          fontSize: 12.sp,
                          color: palette.textMuted,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        e.title ?? e.merchant ?? '—',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.manrope(
                          fontSize: 13.sp,
                          color: palette.textDark,
                        ),
                      ),
                    ),
                    Text(
                      money(e.amount),
                      style: AppTextStyles.manrope(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                        color: palette.textDark,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}
