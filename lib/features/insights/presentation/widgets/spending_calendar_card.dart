import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/neumorphic_styles.dart';
import '../../../../core/theme/theme_cubit.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../currency/presentation/cubit/currency_cubit.dart';
import '../../../currency/presentation/util/currency_formatter.dart';
import '../../../expense/domain/entities/expense_entity.dart';
import '../../domain/services/spending_calendar.dart';

/// Month heatmap of daily spend with the current no-spend streak.
class SpendingCalendarCard extends StatefulWidget {
  const SpendingCalendarCard({super.key, required this.expenses});

  final List<ExpenseEntity> expenses;

  @override
  State<SpendingCalendarCard> createState() => _SpendingCalendarCardState();
}

class _SpendingCalendarCardState extends State<SpendingCalendarCard> {
  /// 0 = current month, -1 = last month…
  int _offset = 0;

  @override
  Widget build(BuildContext context) {
    final palette = context.watch<ThemeCubit>().state.palette;
    final currency = context.watch<CurrencyCubit>();
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final calendar = SpendingCalendar.compute(
      widget.expenses,
      now: now,
      month: DateTime(now.year, now.month + _offset),
    );
    final month = calendar.month;
    // Monday-first grid.
    final leading = (month.weekday - DateTime.monday) % 7;
    final weekdayNames = [
      for (var i = 0; i < 7; i++)
        DateFormat.E(locale).format(DateTime(2024, 1, 1 + i)),
    ];

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.h),
      decoration: NeuBox.raised(palette, radius: 16.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('🔥', style: TextStyle(fontSize: 18.sp)),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  l10n.streak_current(calendar.currentNoSpendStreak),
                  style: AppTextStyles.manrope(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: palette.textDark,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              _NavButton(
                icon: Icons.chevron_left,
                onTap: _offset > -11 ? () => setState(() => _offset--) : null,
              ),
              Expanded(
                child: Text(
                  DateFormat.yMMMM(locale).format(month),
                  textAlign: TextAlign.center,
                  style: AppTextStyles.manrope(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: palette.textDark,
                  ),
                ),
              ),
              _NavButton(
                icon: Icons.chevron_right,
                onTap: _offset < 0 ? () => setState(() => _offset++) : null,
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Row(
            children: [
              for (final name in weekdayNames)
                Expanded(
                  child: Text(
                    name.characters.first,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.manrope(
                      fontSize: 10.sp,
                      color: palette.textMuted,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 6.h),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: leading + calendar.daysInMonth,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 4.h,
              crossAxisSpacing: 4.w,
            ),
            itemBuilder: (context, index) {
              if (index < leading) return const SizedBox.shrink();
              final day = index - leading + 1;
              final date = DateTime(month.year, month.month, day);
              final amount = calendar.dailyTotals[day - 1];
              final future = date.isAfter(today);
              final intensity = calendar.maxDaily <= 0
                  ? 0.0
                  : amount / calendar.maxDaily;

              final color = future
                  ? Colors.transparent
                  : amount > 0
                  ? palette.accent.withValues(alpha: .18 + .82 * intensity)
                  : palette.success.withValues(alpha: .12);

              final label = amount > 0
                  ? '${DateFormat.MMMd(locale).format(date)}: '
                        '${CurrencyFormatter.format(cubit: currency, amountInInr: amount)}'
                  : '${DateFormat.MMMd(locale).format(date)}: '
                        '${l10n.calendar_noSpend}';

              return Tooltip(
                message: future ? '' : label,
                triggerMode: TooltipTriggerMode.tap,
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(6.r),
                    border: date == today
                        ? Border.all(color: palette.textDark, width: 1.2)
                        : null,
                  ),
                  child: Text(
                    '$day',
                    style: AppTextStyles.manrope(
                      fontSize: 10.sp,
                      fontWeight: intensity > .6
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: future
                          ? palette.textMuted.withValues(alpha: .4)
                          : intensity > .6
                          ? Colors.white
                          : palette.textDark,
                    ),
                  ),
                ),
              );
            },
          ),
          SizedBox(height: 10.h),
          Text(
            l10n.streak_monthSummary(
              calendar.noSpendDaysInMonth,
              calendar.longestNoSpendStreakInMonth,
            ),
            style: AppTextStyles.manrope(
              fontSize: 11.sp,
              color: palette.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.watch<ThemeCubit>().state.palette;
    return InkResponse(
      onTap: onTap,
      radius: 18.r,
      child: Icon(
        icon,
        size: 20.sp,
        color: onTap == null
            ? palette.textMuted.withValues(alpha: .3)
            : palette.textDark,
      ),
    );
  }
}
