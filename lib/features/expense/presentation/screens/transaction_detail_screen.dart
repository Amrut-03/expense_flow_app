import 'package:expense_flow_app/core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/expense_category.dart';
import '../../../../core/constants/payment_methods.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/neumorphic_styles.dart';
import '../../../../core/theme/theme_cubit.dart';
import '../../../../core/widgets/neu_app_bar.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../currency/presentation/cubit/currency_cubit.dart';
import '../../../currency/presentation/util/currency_formatter.dart';
import '../../domain/entities/expense_entity.dart';
import '../bloc/expense_bloc.dart';
import '../bloc/expense_event.dart';
import '../bloc/expense_state.dart';
import '../widgets/detail_row.dart';
import '../widgets/pillow_button.dart';

class TransactionDetailScreen extends StatelessWidget {
  final ExpenseEntity expense;

  const TransactionDetailScreen({super.key, required this.expense});

  ExpenseCategory _categoryOf(ExpenseEntity expense) =>
      ExpenseCategories.byId(expense.categoryId);

  ExpenseEntity _resolveExpense(BuildContext context) {
    final state = context.watch<ExpenseBloc>().state;

    if (state is ExpenseLoaded) {
      for (final expense in state.expenses) {
        if (expense.id == this.expense.id) return expense;
      }
    }

    return expense;
  }

  Future<void> _confirmDelete(
    BuildContext context,
    NeuPalette palette,
    ExpenseEntity expense,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        final l10n = AppLocalizations.of(context);
        return AlertDialog(
          backgroundColor: palette.background,
          title: Text(
            l10n.detail_deleteTransaction,
            style: AppTextStyles.manrope(
              color: palette.textDark,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Text(
            l10n.detail_deleteConfirm,
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

    if (confirmed != true) return;

    if (!context.mounted) return;

    context.read<ExpenseBloc>().add(DeleteExpenseEvent(expense.id));

    context.go('/dashboard');
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.watch<ThemeCubit>().state.palette;
    final l10n = AppLocalizations.of(context);
    final currencyCubit = context.watch<CurrencyCubit>();
    final expense = _resolveExpense(context);
    final category = _categoryOf(expense);

    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 8.h),
              NeuAppBar(
                title: l10n.detail_transactionDetails,
                onBack: () => context.pop(),
              ),
              SizedBox(height: 24.h),
              Column(
                    children: [
                      Container(
                        width: 72.r,
                        height: 72.r,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: palette.accent,
                        ),
                        child: Center(
                          child: Text(
                            category.emoji,
                            style: TextStyle(fontSize: 32.sp),
                          ),
                        ),
                      ),
                      SizedBox(height: 16.h),
                      Text(
                        CurrencyFormatter.format(
                          cubit: currencyCubit,
                          amountInInr: expense.amount,
                        ),
                        style: AppTextStyles.manrope(
                          fontSize: 32.sp,
                          fontWeight: FontWeight.bold,
                          color: palette.textDark,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        category.labelOf(l10n),
                        style: AppTextStyles.manrope(
                          fontSize: 15.sp,
                          color: palette.textMuted,
                        ),
                      ),
                      if (expense.title != null &&
                          expense.title!.trim().isNotEmpty) ...[
                        SizedBox(height: 4.h),
                        Text(
                          expense.title!,
                          style: AppTextStyles.manrope(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w600,
                            color: palette.textDark,
                          ),
                        ),
                      ],
                    ],
                  )
                  .animate()
                  .fadeIn(duration: 280.ms, curve: Curves.easeOut)
                  .scale(
                    begin: const Offset(0.96, 0.96),
                    end: const Offset(1, 1),
                    curve: Curves.easeOutCubic,
                  ),
              SizedBox(height: 28.h),
              Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 4.h,
                    ),
                    decoration: NeuBox.raised(palette, radius: 16.r),
                    child: Column(
                      children: [
                        DetailRow(
                          palette: palette,
                          icon: Icons.calendar_today_outlined,
                          label: l10n.detail_date,
                          value: DateFormat(
                            'MMMM d, yyyy · h:mm a',
                          ).format(expense.date),
                        ),
                        Divider(
                          color: palette.textMuted.withValues(alpha: .2),
                          height: 1,
                        ),
                        DetailRow(
                          palette: palette,
                          icon: Icons.category_outlined,
                          label: l10n.detail_category,
                          value: category.labelOf(l10n),
                        ),
                        Divider(
                          color: palette.textMuted.withValues(alpha: .2),
                          height: 1,
                        ),
                        if (expense.paymentMethod != null &&
                            expense.paymentMethod!.trim().isNotEmpty) ...[
                          DetailRow(
                            palette: palette,
                            icon: Icons.payment_outlined,
                            label: l10n.detail_paymentMethod,
                            value: PaymentMethods.localizedLabel(
                              l10n,
                              expense.paymentMethod!,
                            ),
                          ),
                          Divider(
                            color: palette.textMuted.withValues(alpha: .2),
                            height: 1,
                          ),
                        ],
                        DetailRow(
                          palette: palette,
                          icon: Icons.currency_exchange,
                          label: l10n.detail_currency,
                          value: expense.currency,
                        ),
                      ],
                    ),
                  )
                  .animate(delay: 100.ms)
                  .fadeIn(duration: 260.ms, curve: Curves.easeOut)
                  .slideY(begin: 0.05, end: 0, curve: Curves.easeOutCubic),
              SizedBox(height: 16.h),
              Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(16.r),
                    decoration: NeuBox.raised(palette, radius: 16.r),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.description_outlined,
                              color: palette.textMuted,
                              size: 18.sp,
                            ),
                            SizedBox(width: 10.w),
                            Text(
                              'Note',
                              style: AppTextStyles.manrope(
                                fontSize: 15.sp,
                                color: palette.textMuted,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 10.h),
                        Text(
                          expense.note?.trim().isNotEmpty == true
                              ? expense.note!
                              : l10n.detail_noNote,
                          style: AppTextStyles.manrope(
                            fontSize: 15.sp,
                            color: palette.textDark,
                            fontWeight: FontWeight.w500,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  )
                  .animate(delay: 180.ms)
                  .fadeIn(duration: 260.ms, curve: Curves.easeOut)
                  .slideY(begin: 0.05, end: 0, curve: Curves.easeOutCubic),
              const Spacer(),
              Row(
                    children: [
                      Expanded(
                        child: PillowButton(
                          palette: palette,
                          bgColor: palette.accent,
                          icon: Icons.edit_outlined,
                          label: l10n.common_edit,
                          textColor: palette.textDark,
                          onTap: () =>
                              context.push('/edit-expense', extra: expense),
                        ),
                      ),
                      SizedBox(width: 14.w),
                      Expanded(
                        child: PillowButton(
                          palette: palette,
                          bgColor: palette.accent,
                          icon: Icons.delete_outline,
                          label: l10n.common_delete,
                          textColor: palette.textDark,
                          onTap: () =>
                              _confirmDelete(context, palette, expense),
                        ),
                      ),
                    ],
                  )
                  .animate(delay: 260.ms)
                  .fadeIn(duration: 260.ms, curve: Curves.easeOut)
                  .slideY(begin: 0.05, end: 0, curve: Curves.easeOutCubic),
              SizedBox(height: 16.h),
            ],
          ),
        ),
      ),
    );
  }
}
