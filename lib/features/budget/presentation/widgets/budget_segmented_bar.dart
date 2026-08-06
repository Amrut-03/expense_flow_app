import 'package:expense_flow_app/core/theme/app_text_styles.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/expense_category.dart';
import '../../../../core/theme/neumorphic_styles.dart';
import '../../../../l10n/app_localizations.dart';

class BudgetSegmentedBar extends StatelessWidget {
  const BudgetSegmentedBar({
    super.key,
    required this.categories,
    required this.categorySpent,
    required this.totalSpent,
    required this.palette,
    required this.currencySymbol,
    required this.convert,
    this.maxSegments = 5,
  });

  final List<ExpenseCategory> categories;
  final Map<String, double> categorySpent;
  final double totalSpent;
  final dynamic palette;
  final String currencySymbol;
  final double Function(double) convert;
  final int maxSegments;

  @override
  Widget build(BuildContext context) {
    if (totalSpent <= 0 || categories.isEmpty) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);

    final sorted = [...categories]
      ..sort(
        (a, b) =>
            (categorySpent[b.id] ?? 0).compareTo(categorySpent[a.id] ?? 0),
      );

    final topCategories = sorted.take(maxSegments).toList();
    final otherCategories = sorted.skip(maxSegments).toList();
    final othersSpent = otherCategories.fold<double>(
      0,
      (s, c) => s + (categorySpent[c.id] ?? 0),
    );

    final segments = <_BudgetSegment>[
      for (int i = 0; i < topCategories.length; i++)
        _BudgetSegment(
          label: topCategories[i].labelOf(l10n),
          amount: categorySpent[topCategories[i].id] ?? 0,
          color: ExpenseCategories.colorFor(palette, topCategories[i].id),
        ),
      if (othersSpent > 0)
        _BudgetSegment(
          label: 'Others',
          amount: othersSpent,
          color: palette.textDark.withValues(alpha: .25),
        ),
    ];

    return Container(
      width: double.infinity,
      decoration: NeuBox.raised(palette, radius: 16.r),
      padding: EdgeInsets.all(20.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Spending breakdown',
                style: AppTextStyles.manrope(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: palette.textDark,
                ),
              ),
              Text(
                '$currencySymbol${convert(totalSpent).toStringAsFixed(0)} spent',
                style: AppTextStyles.manrope(
                  fontSize: 12.sp,
                  color: palette.textDark.withValues(alpha: .5),
                ),
              ),
            ],
          ),
          SizedBox(height: 14.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(6.r),
            child: SizedBox(
              height: 10.h,
              child: Row(
                children: [
                  for (final seg in segments)
                    Expanded(
                      flex: ((seg.amount / totalSpent) * 1000).round().clamp(
                        1,
                        1000,
                      ),
                      child: Container(color: seg.color),
                    ),
                ],
              ),
            ),
          ),
          SizedBox(height: 14.h),
          Wrap(
            spacing: 16.w,
            runSpacing: 8.h,
            children: [
              for (final seg in segments)
                _LegendItem(
                  color: seg.color,
                  label: seg.label,
                  percent: seg.amount / totalSpent * 100,
                  palette: palette,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BudgetSegment {
  _BudgetSegment({
    required this.label,
    required this.amount,
    required this.color,
  });

  final String label;
  final double amount;
  final Color color;
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({
    required this.color,
    required this.label,
    required this.percent,
    required this.palette,
  });

  final Color color;
  final String label;
  final double percent;
  final dynamic palette;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7.w,
          height: 7.w,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        SizedBox(width: 6.w),
        Text(
          '$label · ${percent.toStringAsFixed(0)}%',
          style: AppTextStyles.manrope(
            fontSize: 12.sp,
            color: palette.textDark.withValues(alpha: .6),
          ),
        ),
      ],
    );
  }
}
