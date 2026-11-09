import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/expense_category.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/neumorphic_styles.dart';
import '../../../../core/theme/theme_cubit.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../currency/presentation/cubit/currency_cubit.dart';
import '../../domain/entities/answer_chart.dart';
import '../../domain/services/answer_chart_planner.dart';

/// Small chart rendered under an AI answer.
class AnswerChartView extends StatelessWidget {
  const AnswerChartView({super.key, required this.chart});

  final AnswerChart chart;

  @override
  Widget build(BuildContext context) {
    final palette = context.watch<ThemeCubit>().state.palette;
    final l10n = AppLocalizations.of(context);

    final category = chart.categoryId == null
        ? null
        : ExpenseCategories.byId(chart.categoryId!);
    final title = switch (chart.kind) {
      AnswerChartKind.categoryBreakdown => l10n.chart_breakdown,
      AnswerChartKind.monthlyTrend => l10n.chart_trend,
      AnswerChartKind.dailySpend => l10n.chart_daily,
      AnswerChartKind.budgetUsage => l10n.chart_budgets,
    };
    final subtitle = [
      ?category == null ? null : '${category.emoji} ${category.labelOf(l10n)}',
      _periodLabel(l10n, chart.period),
    ].join(' · ');

    return Container(
      width: math.min(320.w, MediaQuery.sizeOf(context).width * .8),
      margin: EdgeInsets.only(top: 4.h, bottom: 4.h),
      padding: EdgeInsets.fromLTRB(14.w, 12.h, 14.w, 12.h),
      decoration: NeuBox.raised(palette, radius: 16.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '📊 $title',
            style: AppTextStyles.manrope(
              fontSize: 13.sp,
              fontWeight: FontWeight.w700,
              color: palette.textDark,
            ),
          ),
          Text(
            subtitle,
            style: AppTextStyles.manrope(
              fontSize: 11.sp,
              color: palette.textMuted,
            ),
          ),
          SizedBox(height: 12.h),
          switch (chart.kind) {
            AnswerChartKind.categoryBreakdown => _Breakdown(chart: chart),
            AnswerChartKind.budgetUsage => _BudgetBars(chart: chart),
            AnswerChartKind.monthlyTrend ||
            AnswerChartKind.dailySpend => _Bars(chart: chart),
          },
        ],
      ),
    );
  }

  static String _periodLabel(AppLocalizations l10n, AnswerChartPeriod p) =>
      switch (p) {
        AnswerChartPeriod.thisWeek => l10n.chart_thisWeek,
        AnswerChartPeriod.thisMonth => l10n.chart_thisMonth,
        AnswerChartPeriod.lastMonth => l10n.chart_lastMonth,
        AnswerChartPeriod.lastSixMonths => l10n.chart_lastSixMonths,
        AnswerChartPeriod.thisYear => l10n.chart_thisYear,
      };
}

String _compact(CurrencyCubit currency, double inr) {
  final value = currency.convertFromInr(inr);
  return '${currency.state.selected.symbol}'
      '${NumberFormat.compact(locale: 'en_IN').format(value)}';
}

Color _categoryColor(NeuPalette palette, String id, int index) =>
    id == AnswerChartPlanner.otherKey
    ? palette.textMuted.withValues(alpha: .5)
    : ExpenseCategories.colorFor(palette, id);

class _Breakdown extends StatelessWidget {
  const _Breakdown({required this.chart});

  final AnswerChart chart;

  @override
  Widget build(BuildContext context) {
    final palette = context.watch<ThemeCubit>().state.palette;
    final currency = context.watch<CurrencyCubit>();
    final l10n = AppLocalizations.of(context);
    final total = chart.total;

    return Row(
      children: [
        SizedBox(
          width: 110.r,
          height: 110.r,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 30.r,
              sections: [
                for (var i = 0; i < chart.points.length; i++)
                  PieChartSectionData(
                    value: chart.points[i].value,
                    color: _categoryColor(palette, chart.points[i].key, i),
                    radius: 22.r,
                    showTitle: false,
                  ),
              ],
            ),
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < chart.points.length; i++)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 2.h),
                  child: Row(
                    children: [
                      Container(
                        width: 8.r,
                        height: 8.r,
                        decoration: BoxDecoration(
                          color: _categoryColor(
                            palette,
                            chart.points[i].key,
                            i,
                          ),
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: 6.w),
                      Expanded(
                        child: Text(
                          chart.points[i].key == AnswerChartPlanner.otherKey
                              ? l10n.chart_other
                              : ExpenseCategories.byId(
                                  chart.points[i].key,
                                ).labelOf(l10n),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.manrope(
                            fontSize: 11.sp,
                            color: palette.textDark,
                          ),
                        ),
                      ),
                      Text(
                        '${(chart.points[i].value / total * 100).round()}% · '
                        '${_compact(currency, chart.points[i].value)}',
                        style: AppTextStyles.manrope(
                          fontSize: 11.sp,
                          color: palette.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Bars extends StatelessWidget {
  const _Bars({required this.chart});

  final AnswerChart chart;

  @override
  Widget build(BuildContext context) {
    final palette = context.watch<ThemeCubit>().state.palette;
    final currency = context.watch<CurrencyCubit>();
    final l10n = AppLocalizations.of(context);
    final monthly = chart.kind == AnswerChartKind.monthlyTrend;
    final points = chart.points;
    final maxY = points.fold<double>(0, (m, p) => math.max(m, p.value));
    final barColor = chart.categoryId == null
        ? palette.accent
        : ExpenseCategories.colorFor(palette, chart.categoryId!);

    String label(int i) {
      final date = DateTime.parse(
        monthly ? '${points[i].key}-01' : points[i].key,
      );
      return monthly
          ? DateFormat.MMM(l10n.localeName).format(date)
          : '${date.day}';
    }

    // Daily charts label every ~5th day so labels don't collide.
    final step = monthly ? 1 : math.max(1, (points.length / 6).ceil());

    return SizedBox(
      height: 140.h,
      child: BarChart(
        BarChartData(
          maxY: maxY <= 0 ? 1 : maxY * 1.15,
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => palette.textDark,
              getTooltipItem: (group, _, rod, _) => BarTooltipItem(
                '${label(group.x)}\n${_compact(currency, rod.toY)}',
                AppTextStyles.manrope(
                  fontSize: 11.sp,
                  color: palette.background,
                ),
              ),
            ),
          ),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(),
            rightTitles: const AxisTitles(),
            leftTitles: const AxisTitles(),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 20.h,
                getTitlesWidget: (value, meta) {
                  final i = value.toInt();
                  if (i < 0 || i >= points.length || i % step != 0) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: EdgeInsets.only(top: 4.h),
                    child: Text(
                      label(i),
                      style: AppTextStyles.manrope(
                        fontSize: 10.sp,
                        color: palette.textMuted,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          barGroups: [
            for (var i = 0; i < points.length; i++)
              BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: points[i].value,
                    color: barColor,
                    width: monthly ? 18.w : math.max(3, 200.w / points.length),
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(4.r),
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

class _BudgetBars extends StatelessWidget {
  const _BudgetBars({required this.chart});

  final AnswerChart chart;

  @override
  Widget build(BuildContext context) {
    final palette = context.watch<ThemeCubit>().state.palette;
    final currency = context.watch<CurrencyCubit>();
    final l10n = AppLocalizations.of(context);

    return Column(
      children: [
        for (final p in chart.points)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 4.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${ExpenseCategories.byId(p.key).emoji} '
                        '${ExpenseCategories.byId(p.key).labelOf(l10n)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.manrope(
                          fontSize: 11.sp,
                          color: palette.textDark,
                        ),
                      ),
                    ),
                    Text(
                      '${_compact(currency, p.value)} / '
                      '${_compact(currency, p.limit!)}',
                      style: AppTextStyles.manrope(
                        fontSize: 11.sp,
                        color: p.value > p.limit!
                            ? palette.danger
                            : palette.textMuted,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4.h),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6.r),
                  child: LinearProgressIndicator(
                    value: p.limit! <= 0
                        ? 0
                        : (p.value / p.limit!).clamp(0, 1).toDouble(),
                    minHeight: 6.h,
                    backgroundColor: palette.textMuted.withValues(alpha: .15),
                    valueColor: AlwaysStoppedAnimation(
                      p.value > p.limit! ? palette.danger : palette.accent,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
