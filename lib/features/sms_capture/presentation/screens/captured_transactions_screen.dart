import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/expense_category.dart';
import '../../../../core/constants/payment_methods.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/neumorphic_styles.dart';
import '../../../../core/theme/theme_cubit.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/neu_app_bar.dart';
import '../../../../core/widgets/neu_bottom_sheet.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/widgets/neu_snack_bar.dart';
import '../../../expense/domain/validation/expense_validator.dart';
import '../../../expense/presentation/bloc/expense_bloc.dart';
import '../../domain/entities/captured_transaction.dart';
import '../cubit/sms_capture_cubit.dart';

/// Review queue for payments detected from SMS. Nothing becomes an expense
/// until the user taps Add.
import '../capture_expense_event.dart';

class CapturedTransactionsScreen extends StatefulWidget {
  const CapturedTransactionsScreen({super.key});

  @override
  State<CapturedTransactionsScreen> createState() =>
      _CapturedTransactionsScreenState();
}

class _CapturedTransactionsScreenState
    extends State<CapturedTransactionsScreen> {
  /// Category overrides chosen on this screen, by capture id.
  final Map<String, String> _chosen = {};

  String _categoryFor(CapturedTransaction c) =>
      _chosen[c.id] ?? c.suggestedCategoryId ?? 'other';

  Future<void> _accept(CapturedTransaction c) async {
    final l10n = AppLocalizations.of(context);
    // Keep the capture queued if it can't become a valid expense, rather
    // than marking it accepted and silently losing it.
    if (c.amount > ExpenseValidator.maxAmount) {
      NeuSnackBar.show(
        context: context,
        message: l10n.capture_tooLarge,
        type: NeuSnackBarType.error,
      );
      return;
    }
    context.read<ExpenseBloc>().add(
      captureToExpenseEvent(
        c,
        categoryId: _categoryFor(c),
        fallbackTitle: l10n.capture_defaultTitle,
      ),
    );
    await context.read<SmsCaptureCubit>().markResolved(c, accepted: true);
  }

  Future<void> _pickCategory(CapturedTransaction c) async {
    final l10n = AppLocalizations.of(context);
    final palette = context.read<ThemeCubit>().state.palette;
    final picked = await NeuBottomSheet.show<String>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 20.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SheetDragHandle(),
              SizedBox(height: 16.h),
              Wrap(
                spacing: 10.w,
                runSpacing: 10.h,
                children: [
                  for (final cat in ExpenseCategories.all)
                    ActionChip(
                      backgroundColor: palette.background,
                      avatar: Text(cat.emoji),
                      label: Text(
                        cat.labelOf(l10n),
                        style: AppTextStyles.manrope(color: palette.textDark),
                      ),
                      onPressed: () => Navigator.of(sheetContext).pop(cat.id),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (picked != null) setState(() => _chosen[c.id] = picked);
  }

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
                title: l10n.capture_title,
                onBack: () => context.pop(),
              ),
            ),
            Expanded(
              child: BlocBuilder<SmsCaptureCubit, SmsCaptureState>(
                builder: (context, state) {
                  if (state.pending.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24.w),
                        child: EmptyStateWidget(
                          icon: Text('✅', style: TextStyle(fontSize: 40.sp)),
                          title: l10n.capture_emptyTitle,
                          subtitle: l10n.capture_emptyHint,
                        ),
                      ),
                    );
                  }
                  return ListView.separated(
                    padding: EdgeInsets.fromLTRB(24.w, 20.h, 24.w, 24.h),
                    itemCount: state.pending.length,
                    separatorBuilder: (_, _) => SizedBox(height: 12.h),
                    itemBuilder: (context, i) => _captureCard(state.pending[i]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _captureCard(CapturedTransaction c) {
    final palette = context.watch<ThemeCubit>().state.palette;
    final l10n = AppLocalizations.of(context);
    final category = ExpenseCategories.byId(_categoryFor(c));
    final amount = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 2,
    ).format(c.amount);

    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: NeuBox.raised(palette, radius: 20.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  c.merchant ?? l10n.capture_unknownMerchant,
                  style: AppTextStyles.manrope(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w600,
                    color: palette.textDark,
                  ),
                ),
              ),
              Text(
                amount,
                style: AppTextStyles.manrope(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.bold,
                  color: palette.textDark,
                ),
              ),
            ],
          ),
          SizedBox(height: 4.h),
          Text(
            '${DateFormat('d MMM, h:mm a').format(c.date)} · '
            '${PaymentMethods.localizedLabel(l10n, c.paymentMethod)} · ${c.sender}',
            style: AppTextStyles.manrope(
              fontSize: 12.sp,
              color: palette.textMuted,
            ),
          ),
          if (c.possibleDuplicate) ...[
            SizedBox(height: 6.h),
            Text(
              l10n.capture_possibleDuplicate,
              style: AppTextStyles.manrope(
                fontSize: 12.sp,
                color: palette.danger,
              ),
            ),
          ],
          SizedBox(height: 10.h),
          Row(
            children: [
              ActionChip(
                backgroundColor: palette.background,
                avatar: Text(category.emoji),
                label: Text(
                  category.labelOf(l10n),
                  style: AppTextStyles.manrope(
                    fontSize: 12.sp,
                    color: palette.textDark,
                  ),
                ),
                onPressed: () => _pickCategory(c),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => context.read<SmsCaptureCubit>().markResolved(
                  c,
                  accepted: false,
                ),
                child: Text(
                  l10n.capture_dismiss,
                  style: AppTextStyles.manrope(color: palette.textMuted),
                ),
              ),
              TextButton(
                onPressed: () => _accept(c),
                child: Text(
                  l10n.capture_add,
                  style: AppTextStyles.manrope(
                    fontWeight: FontWeight.w600,
                    color: palette.accent,
                  ),
                ),
              ),
            ],
          ),
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            dense: true,
            title: Text(
              l10n.capture_showSms,
              style: AppTextStyles.manrope(
                fontSize: 12.sp,
                color: palette.textMuted,
              ),
            ),
            children: [
              Text(
                c.body,
                style: AppTextStyles.manrope(
                  fontSize: 12.sp,
                  color: palette.textDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
