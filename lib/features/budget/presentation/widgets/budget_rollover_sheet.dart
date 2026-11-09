import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/theme_cubit.dart';
import '../../../../core/widgets/neu_bottom_sheet.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../goals/domain/entities/savings_goal.dart';
import '../../domain/entities/budget_rollover.dart';

/// Short label for a rollover setting, e.g. "Rollover: carry forward".
String rolloverLabel(
  AppLocalizations l10n,
  BudgetRolloverSetting setting,
  List<SavingsGoal> goals,
) {
  switch (setting.mode) {
    case BudgetRolloverMode.none:
      return l10n.rollover_off;
    case BudgetRolloverMode.carryForward:
      return l10n.rollover_carryForward;
    case BudgetRolloverMode.toGoal:
      final goal = goals.where((g) => g.id == setting.goalId).firstOrNull;
      return goal == null
          ? l10n.rollover_toGoalShort
          : l10n.rollover_toGoalNamed('${goal.emoji} ${goal.name}');
  }
}

/// Lets the user pick what happens to a category's unspent budget.
abstract final class BudgetRolloverSheet {
  static Future<BudgetRolloverSetting?> show(
    BuildContext context, {
    required BudgetRolloverSetting current,
    required List<SavingsGoal> goals,
  }) {
    return NeuBottomSheet.show<BudgetRolloverSetting>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        final palette = sheetContext.watch<ThemeCubit>().state.palette;
        final l10n = AppLocalizations.of(sheetContext);

        Widget option({
          required String title,
          required String subtitle,
          required BudgetRolloverSetting value,
          String? leading,
        }) {
          final selected = value == current;
          return ListTile(
            contentPadding: EdgeInsets.symmetric(horizontal: 4.w),
            leading: leading == null
                ? null
                : Text(leading, style: TextStyle(fontSize: 20.sp)),
            title: Text(
              title,
              style: AppTextStyles.manrope(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: palette.textDark,
              ),
            ),
            subtitle: Text(
              subtitle,
              style: AppTextStyles.manrope(
                fontSize: 12.sp,
                color: palette.textMuted,
              ),
            ),
            trailing: selected
                ? Icon(Icons.check_circle, color: palette.accent)
                : null,
            onTap: () => Navigator.of(sheetContext).pop(value),
          );
        }

        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 12.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.rollover_title,
                  style: AppTextStyles.manrope(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: palette.textDark,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  l10n.rollover_hint,
                  style: AppTextStyles.manrope(
                    fontSize: 12.sp,
                    color: palette.textMuted,
                  ),
                ),
                SizedBox(height: 8.h),
                option(
                  leading: '⏹️',
                  title: l10n.rollover_off,
                  subtitle: l10n.rollover_offHint,
                  value: BudgetRolloverSetting.off,
                ),
                option(
                  leading: '➡️',
                  title: l10n.rollover_carryForward,
                  subtitle: l10n.rollover_carryForwardHint,
                  value: const BudgetRolloverSetting(
                    mode: BudgetRolloverMode.carryForward,
                  ),
                ),
                if (goals.isEmpty)
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.h),
                    child: Text(
                      l10n.rollover_noGoals,
                      style: AppTextStyles.manrope(
                        fontSize: 12.sp,
                        color: palette.textMuted,
                      ),
                    ),
                  )
                else
                  for (final goal in goals)
                    option(
                      leading: goal.emoji,
                      title: l10n.rollover_toGoalNamed(goal.name),
                      subtitle: l10n.rollover_toGoalHint,
                      value: BudgetRolloverSetting(
                        mode: BudgetRolloverMode.toGoal,
                        goalId: goal.id,
                      ),
                    ),
              ],
            ),
          ),
        );
      },
    );
  }
}
