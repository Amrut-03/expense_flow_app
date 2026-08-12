import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/expense_category.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/theme_cubit.dart';

class CategorySpending {
  final ExpenseCategory category;
  final double amount;

  const CategorySpending({required this.category, required this.amount});
}

class SpendingPieChart extends StatelessWidget {
  final List<CategorySpending> slices;
  final double height;

  const SpendingPieChart({
    super.key,
    required this.slices,
    this.height = 220,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.watch<ThemeCubit>().state.palette;

    final visible = slices.where((s) => s.amount > 0).toList();
    final total = visible.fold<double>(0, (sum, s) => sum + s.amount);

    if (visible.isEmpty || total <= 0) {
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

    return SizedBox(
      height: height,
      child: PieChart(
        PieChartData(
          sectionsSpace: 6,
          centerSpaceRadius: 48,
          startDegreeOffset: -90,
          sections: visible.map((slice) {
            final index = ExpenseCategories.all.indexWhere(
              (c) => c.id == slice.category.id,
            );
            final color =
                index >= 0 && index < palette.categoryColors.length
                    ? palette.categoryColors[index]
                    : palette.accent;
            final percentage = (slice.amount / total * 100).clamp(0, 100);
            return PieChartSectionData(
              value: slice.amount,
              color: color,
              radius: 44,
              showTitle: percentage >= 8,
              title: '${percentage.toStringAsFixed(0)}%',
              titleStyle: AppTextStyles.manrope(
                fontSize: 11.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}