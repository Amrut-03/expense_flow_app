import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/expense_category.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/neumorphic_styles.dart';
import '../../../../core/theme/theme_cubit.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/neu_app_bar.dart';
import '../../../../core/widgets/neu_loading.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../currency/presentation/cubit/currency_cubit.dart';
import '../../../currency/presentation/util/currency_formatter.dart';
import '../../domain/entities/recurring_expense_entity.dart';
import '../../domain/services/recurrence_calculator.dart';
import '../cubit/recurring_expenses_cubit.dart';
import '../recurrence_labels.dart';

class RecurringExpensesScreen extends StatelessWidget {
  const RecurringExpensesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = context.watch<ThemeCubit>().state.palette;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(24.w, 10.h, 24.w, 0),
              child: NeuAppBar(
                title: l10n.recurring_title,
                onBack: () => context.pop(),
              ),
            ),
            Expanded(
              child:
                  BlocBuilder<RecurringExpensesCubit, RecurringExpensesState>(
                    builder: (context, state) {
                      if (state.status == RecurringExpensesStatus.loading) {
                        return const Center(child: NeuLoading());
                      }

                      if (state.rules.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 24.w),
                            child: EmptyStateWidget(
                              icon: Text(
                                '🔁',
                                style: TextStyle(fontSize: 40.sp),
                              ),
                              title: l10n.recurring_emptyTitle,
                              subtitle: state.error ?? l10n.recurring_emptyHint,
                            ),
                          ),
                        );
                      }

                      return ListView.separated(
                        padding: EdgeInsets.fromLTRB(24.w, 20.h, 24.w, 24.h),
                        itemCount: state.rules.length,
                        separatorBuilder: (_, _) => SizedBox(height: 12.h),
                        itemBuilder: (context, index) =>
                            _RuleTile(rule: state.rules[index]),
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

class _RuleTile extends StatelessWidget {
  const _RuleTile({required this.rule});

  final RecurringExpenseEntity rule;

  @override
  Widget build(BuildContext context) {
    final palette = context.watch<ThemeCubit>().state.palette;
    final currency = context.watch<CurrencyCubit>();
    final l10n = AppLocalizations.of(context);
    final category = ExpenseCategories.byId(rule.categoryId);
    final cubit = context.read<RecurringExpensesCubit>();

    final name = rule.title ?? rule.merchant ?? category.labelOf(l10n);
    final schedule = rule.isActive
        ? l10n.recurring_nextDue(
            DateFormat.yMMMd(
              l10n.localeName,
            ).format(RecurrenceCalculator.nextDueDate(rule)),
          )
        : l10n.recurring_paused;

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
                  name,
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
                  '${CurrencyFormatter.format(cubit: currency, amountInInr: rule.amount)}'
                  ' · ${rule.frequency.label(l10n)}',
                  style: AppTextStyles.manrope(
                    fontSize: 12.sp,
                    color: palette.textMuted,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  schedule,
                  style: AppTextStyles.manrope(
                    fontSize: 12.sp,
                    color: rule.isActive ? palette.accent : palette.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: rule.isActive,
            activeThumbColor: palette.accent,
            onChanged: (active) => cubit.setActive(rule.id, active),
          ),
          IconButton(
            tooltip: l10n.common_delete,
            icon: Icon(Icons.delete_outline, color: palette.textMuted),
            onPressed: () => _confirmDelete(context, palette, cubit),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    NeuPalette palette,
    RecurringExpensesCubit cubit,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        final l10n = AppLocalizations.of(context);
        return AlertDialog(
          backgroundColor: palette.background,
          title: Text(
            l10n.recurring_deleteTitle,
            style: AppTextStyles.manrope(
              color: palette.textDark,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Text(
            l10n.recurring_deleteMessage,
            style: AppTextStyles.manrope(color: palette.textMuted),
          ),
          actions: [
            TextButton(
              onPressed: () => context.pop(false),
              child: Text(
                l10n.common_cancel,
                style: AppTextStyles.manrope(color: palette.textMuted),
              ),
            ),
            TextButton(
              onPressed: () => context.pop(true),
              child: Text(
                l10n.common_delete,
                style: AppTextStyles.manrope(
                  color: palette.accent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed == true) await cubit.delete(rule.id);
  }
}
