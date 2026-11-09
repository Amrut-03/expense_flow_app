import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/expense_category.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/neumorphic_styles.dart';
import '../../../../core/theme/theme_cubit.dart';
import '../../../../core/widgets/neu_app_bar.dart';
import '../../../../core/widgets/neu_bottom_sheet.dart';
import '../../../../core/widgets/neu_button.dart';
import '../../../../core/widgets/neu_loading.dart';
import '../../../../core/widgets/neu_text_field.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../currency/presentation/cubit/currency_cubit.dart';
import '../../../currency/presentation/util/currency_formatter.dart';
import '../../domain/entities/envelope.dart';
import '../../domain/usecases/envelope_usecases.dart';
import '../bloc/envelope_cubit.dart';

/// Zero-based envelope budgeting: give every rupee of income a job, carry
/// envelope balances month to month, move money to cover overspending.
class EnvelopesScreen extends StatelessWidget {
  const EnvelopesScreen({super.key});

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
                title: l10n.envelopes_title,
                onBack: () => context.pop(),
              ),
            ),
            Expanded(
              child: BlocBuilder<EnvelopeCubit, EnvelopeState>(
                builder: (context, state) {
                  if (state.loading) return const Center(child: NeuLoading());
                  if (!state.enabled || state.month == null) {
                    return const _Intro();
                  }
                  return _Envelopes(month: state.month!);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Intro extends StatelessWidget {
  const _Intro();

  @override
  Widget build(BuildContext context) {
    final palette = context.watch<ThemeCubit>().state.palette;
    final l10n = AppLocalizations.of(context);
    return ListView(
      padding: EdgeInsets.all(24.r),
      children: [
        Container(
          padding: EdgeInsets.all(20.r),
          decoration: NeuBox.raised(palette, radius: 18.r),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('✉️', style: TextStyle(fontSize: 32.sp)),
              SizedBox(height: 8.h),
              _text(palette, l10n.envelopes_introTitle, size: 16, bold: true),
              SizedBox(height: 8.h),
              for (final line in [
                l10n.envelopes_intro1,
                l10n.envelopes_intro2,
                l10n.envelopes_intro3,
              ])
                Padding(
                  padding: EdgeInsets.only(bottom: 6.h),
                  child: _text(palette, '•  $line', size: 13),
                ),
              SizedBox(height: 4.h),
              _text(palette, l10n.envelopes_introNote, size: 11, muted: true),
              SizedBox(height: 16.h),
              SizedBox(
                width: double.infinity,
                child: NeuButton(
                  label: l10n.envelopes_turnOn,
                  onTap: () => context.read<EnvelopeCubit>().setEnabled(true),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Envelopes extends StatelessWidget {
  const _Envelopes({required this.month});

  final EnvelopeMonth month;

  @override
  Widget build(BuildContext context) {
    final palette = context.watch<ThemeCubit>().state.palette;
    final currency = context.watch<CurrencyCubit>();
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<EnvelopeCubit>();
    String money(double inr) =>
        CurrencyFormatter.format(cubit: currency, amountInInr: inr);

    final tba = month.toBeAssigned;
    final (tbaText, tbaColor) = switch (tba) {
      null => (l10n.envelopes_setIncomePrompt, palette.textMuted),
      final v when v.abs() < 0.5 => (
        l10n.envelopes_allAssigned,
        palette.success,
      ),
      final v when v > 0 => (
        l10n.envelopes_assignRest(money(v)),
        palette.accent,
      ),
      final v => (l10n.envelopes_overAssigned(money(-v)), palette.danger),
    };

    return ListView(
      padding: EdgeInsets.fromLTRB(24.w, 20.h, 24.w, 24.h),
      children: [
        Container(
          padding: EdgeInsets.all(20.r),
          decoration: NeuBox.raised(palette, radius: 18.r),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _text(
                palette,
                l10n.envelopes_toBeAssigned,
                size: 12,
                muted: true,
              ),
              SizedBox(height: 4.h),
              Text(
                tba == null ? '—' : money(tba),
                style: AppTextStyles.manrope(
                  fontSize: 28.sp,
                  fontWeight: FontWeight.bold,
                  color: tbaColor,
                ),
              ),
              SizedBox(height: 6.h),
              _text(palette, tbaText, size: 12),
              SizedBox(height: 12.h),
              Row(
                children: [
                  Expanded(
                    child: _text(
                      palette,
                      month.income == null
                          ? l10n.envelopes_noIncome
                          : l10n.envelopes_income(money(month.income!)),
                      size: 12,
                      muted: true,
                    ),
                  ),
                  TextButton(
                    onPressed: () => _editIncome(context, month.income),
                    child: Text(l10n.envelopes_setIncome),
                  ),
                ],
              ),
              if (tba != null && tba > 0.5)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => context.push('/budget/edit'),
                    icon: const Icon(Icons.tune, size: 18),
                    label: Text(l10n.envelopes_editAllocations),
                  ),
                ),
            ],
          ),
        ),
        if (month.overspent.isNotEmpty) ...[
          SizedBox(height: 12.h),
          Container(
            padding: EdgeInsets.all(14.r),
            decoration: NeuBox.raised(palette, radius: 14.r),
            child: _text(
              palette,
              l10n.envelopes_overspentWarning(month.overspent.length),
              size: 12,
              color: palette.danger,
            ),
          ),
        ],
        SizedBox(height: 20.h),
        if (month.envelopes.isEmpty)
          _text(palette, l10n.envelopes_noEnvelopes, size: 13, muted: true),
        for (final e in month.envelopes) ...[
          _EnvelopeTile(
            balance: e,
            money: money,
            onTap: () => _moveMoney(
              context,
              month,
              to: e.available < 0 ? e.categoryId : null,
              from: e.available >= 0 ? e.categoryId : null,
            ),
          ),
          SizedBox(height: 10.h),
        ],
        SizedBox(height: 8.h),
        if (month.envelopes.length > 1)
          NeuButton(
            label: l10n.envelopes_moveMoney,
            icon: Icons.swap_horiz,
            variant: NeuButtonVariant.secondary,
            onTap: () => _moveMoney(context, month),
          ),
        SizedBox(height: 16.h),
        Center(
          child: TextButton(
            onPressed: () => cubit.setEnabled(false),
            child: Text(
              l10n.envelopes_turnOff,
              style: AppTextStyles.manrope(color: palette.textMuted),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _editIncome(BuildContext context, double? current) {
    final cubit = context.read<EnvelopeCubit>();
    final currency = context.read<CurrencyCubit>();
    final l10n = AppLocalizations.of(context);
    final controller = TextEditingController(
      text: current == null
          ? ''
          : currency.convertFromInr(current).toStringAsFixed(0),
    );
    String? error;
    return NeuBottomSheet.show<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheet) {
          final palette = sheetContext.watch<ThemeCubit>().state.palette;
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
            ),
            child: Padding(
              padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 24.h),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SheetDragHandle(),
                  SizedBox(height: 16.h),
                  _text(
                    palette,
                    l10n.envelopes_setIncome,
                    size: 18,
                    bold: true,
                  ),
                  SizedBox(height: 6.h),
                  _text(
                    palette,
                    l10n.envelopes_incomeHint,
                    size: 12,
                    muted: true,
                  ),
                  SizedBox(height: 16.h),
                  NeuTextField(
                    height: 56.h,
                    controller: controller,
                    hint: currency.state.selected.symbol,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                  if (error != null) ...[
                    SizedBox(height: 8.h),
                    _text(palette, error!, size: 12, color: palette.danger),
                  ],
                  SizedBox(height: 16.h),
                  SizedBox(
                    width: double.infinity,
                    child: NeuButton(
                      label: l10n.events_save,
                      onTap: () async {
                        final v = double.tryParse(controller.text.trim());
                        if (v == null || v < 0) {
                          setSheet(() => error = l10n.addExpense_validAmount);
                          return;
                        }
                        await cubit.setIncome(
                          double.parse(
                            currency
                                .convertToInr(
                                  amount: v,
                                  fromCurrency: currency.state.selected.code,
                                )
                                .toStringAsFixed(2),
                          ),
                        );
                        if (sheetContext.mounted) {
                          Navigator.of(sheetContext).pop();
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _moveMoney(
    BuildContext context,
    EnvelopeMonth month, {
    String? from,
    String? to,
  }) {
    final cubit = context.read<EnvelopeCubit>();
    final currency = context.read<CurrencyCubit>();
    final l10n = AppLocalizations.of(context);
    final amount = TextEditingController();
    final ids = [for (final e in month.envelopes) e.categoryId];
    var fromId = from ?? ids.firstWhere((id) => id != to, orElse: () => ids[0]);
    var toId = to ?? ids.firstWhere((id) => id != fromId, orElse: () => ids[0]);
    final shortfall = to == null ? null : -month.byCategory(to)!.available;
    if (shortfall != null && shortfall > 0) {
      amount.text = currency.convertFromInr(shortfall).toStringAsFixed(0);
    }
    String? error;

    return NeuBottomSheet.show<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheet) {
          final palette = sheetContext.watch<ThemeCubit>().state.palette;
          String money(double inr) =>
              CurrencyFormatter.format(cubit: currency, amountInInr: inr);

          Widget picker(String selected, ValueChanged<String> onPick) => Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: [
              for (final e in month.envelopes)
                GestureDetector(
                  onTap: () => onPick(e.categoryId),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 8.h,
                    ),
                    decoration: NeuBox.raised(
                      palette,
                      radius: 12.r,
                      bgColor: selected == e.categoryId
                          ? palette.accent
                          : palette.background,
                    ),
                    child: Text(
                      '${ExpenseCategories.byId(e.categoryId).emoji} '
                      '${money(e.available)}',
                      style: AppTextStyles.manrope(
                        fontSize: 12.sp,
                        color: selected == e.categoryId
                            ? palette.onAccent
                            : e.available < 0
                            ? palette.danger
                            : palette.textDark,
                      ),
                    ),
                  ),
                ),
            ],
          );

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
            ),
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 24.h),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SheetDragHandle(),
                  SizedBox(height: 16.h),
                  _text(
                    palette,
                    l10n.envelopes_moveMoney,
                    size: 18,
                    bold: true,
                  ),
                  SizedBox(height: 16.h),
                  _text(palette, l10n.envelopes_from, size: 13, bold: true),
                  SizedBox(height: 8.h),
                  picker(fromId, (id) => setSheet(() => fromId = id)),
                  SizedBox(height: 16.h),
                  _text(palette, l10n.envelopes_to, size: 13, bold: true),
                  SizedBox(height: 8.h),
                  picker(toId, (id) => setSheet(() => toId = id)),
                  SizedBox(height: 16.h),
                  NeuTextField(
                    height: 56.h,
                    controller: amount,
                    hint: currency.state.selected.symbol,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                  if (error != null) ...[
                    SizedBox(height: 8.h),
                    _text(palette, error!, size: 12, color: palette.danger),
                  ],
                  SizedBox(height: 16.h),
                  SizedBox(
                    width: double.infinity,
                    child: NeuButton(
                      label: l10n.envelopes_move,
                      onTap: () async {
                        final v = double.tryParse(amount.text.trim()) ?? 0;
                        final inr = currency.convertToInr(
                          amount: v,
                          fromCurrency: currency.state.selected.code,
                        );
                        final failure = await cubit.moveMoney(
                          from: fromId,
                          to: toId,
                          amount: inr,
                        );
                        if (failure != null) {
                          setSheet(
                            () => error = failure == EnvelopeMoveError.amount
                                ? l10n.addExpense_validAmount
                                : l10n.envelopes_sameEnvelope,
                          );
                        } else if (sheetContext.mounted) {
                          Navigator.of(sheetContext).pop();
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _EnvelopeTile extends StatelessWidget {
  const _EnvelopeTile({
    required this.balance,
    required this.money,
    required this.onTap,
  });

  final EnvelopeBalance balance;
  final String Function(double) money;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.watch<ThemeCubit>().state.palette;
    final l10n = AppLocalizations.of(context);
    final category = ExpenseCategories.byId(balance.categoryId);
    final negative = balance.available < -0.005;
    final details = [
      l10n.envelopes_assigned(money(balance.assigned)),
      l10n.envelopes_spent(money(balance.spent)),
      if (balance.carried.abs() >= 0.5)
        l10n.envelopes_carried(money(balance.carried)),
      if (balance.moved.abs() >= 0.5)
        l10n.envelopes_moved(
          '${balance.moved > 0 ? '+' : ''}${money(balance.moved)}',
        ),
    ].join(' · ');

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(14.r),
        decoration: NeuBox.raised(palette, radius: 16.r),
        child: Row(
          children: [
            Text(category.emoji, style: TextStyle(fontSize: 22.sp)),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _text(palette, category.labelOf(l10n), size: 14, bold: true),
                  SizedBox(height: 2.h),
                  _text(palette, details, size: 11, muted: true),
                ],
              ),
            ),
            SizedBox(width: 8.w),
            Text(
              money(balance.available),
              style: AppTextStyles.manrope(
                fontSize: 15.sp,
                fontWeight: FontWeight.bold,
                color: negative ? palette.danger : palette.success,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _text(
  NeuPalette palette,
  String text, {
  required double size,
  bool bold = false,
  bool muted = false,
  Color? color,
}) => Text(
  text,
  style: AppTextStyles.manrope(
    fontSize: size.sp,
    fontWeight: bold ? FontWeight.bold : FontWeight.normal,
    color: color ?? (muted ? palette.textMuted : palette.textDark),
  ),
);
