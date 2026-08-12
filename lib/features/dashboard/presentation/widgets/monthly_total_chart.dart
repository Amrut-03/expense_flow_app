import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/theme_cubit.dart';

class MonthlyTotal {
  final String label;
  final double amount;

  const MonthlyTotal({required this.label, required this.amount});
}

class MonthlyTotalChart extends StatelessWidget {
  final List<MonthlyTotal> data;
  final double height;

  const MonthlyTotalChart({
    super.key,
    required this.data,
    this.height = 180,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.watch<ThemeCubit>().state.palette;

    final nonEmpty = data.where((d) => d.amount > 0).toList();
    if (data.isEmpty || nonEmpty.isEmpty) {
      return SizedBox(
        height: height,
        child: Center(
          child: Text(
            'No spending yet',
            style: AppTextStyles.manrope(
              fontSize: 14.sp,
              color: palette.textMuted,
            ),
          ),
        ),
      );
    }

    final maxY = data.fold<double>(0, (max, d) => d.amount > max ? d.amount : max);
    final chartMax = (maxY * 1.25).clamp(10, double.infinity).toDouble();

    return SizedBox(
      height: height,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: chartMax,
          minY: 0,
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => palette.textDark,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final label = data[group.x].label;
                return BarTooltipItem(
                  '$label\n${rod.toY.toStringAsFixed(0)}',
                  AppTextStyles.manrope(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: palette.background,
                  ),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 26,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= data.length) {
                    return const SizedBox.shrink();
                  }
                  final label = data[index].label;
                  return Padding(
                    padding: EdgeInsets.only(top: 6.h),
                    child: Text(
                      label,
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
          borderData: FlBorderData(show: false),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: chartMax / 4,
            getDrawingHorizontalLine: (value) => FlLine(
              color: palette.textMuted.withValues(alpha: .15),
              strokeWidth: 1,
            ),
          ),
          barGroups: [
            for (int i = 0; i < data.length; i++)
              BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: data[i].amount,
                    color: palette.accent.withValues(
                      alpha: data[i].amount == 0 ? .15 : 1,
                    ),
                    width: 22.w,
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}