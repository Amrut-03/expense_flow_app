import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/constants/expense_category.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/neumorphic_styles.dart';
import '../../../../core/theme/theme_cubit.dart';
import '../../../../core/widgets/neu_app_bar.dart';
import '../../../../core/widgets/neu_bottom_sheet.dart';
import '../../../../core/widgets/neu_button.dart';
import '../../../../core/widgets/neu_loading.dart';
import '../../../../core/widgets/neu_snack_bar.dart';
import '../../../../core/widgets/neu_text_field.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../currency/presentation/cubit/currency_cubit.dart';
import '../../../currency/presentation/util/currency_formatter.dart';
import '../../domain/entities/group.dart';
import '../../domain/repositories/group_repository.dart';
import '../../domain/services/split_math.dart';
import '../../domain/usecases/group_usecases.dart';
import '../cubit/group_detail_cubit.dart';
import '../widgets/group_labels.dart';
import 'groups_screen.dart' show choiceChips, copyText, errorText, sheetTitle;

class GroupDetailScreen extends StatelessWidget {
  const GroupDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = context.watch<ThemeCubit>().state.palette;
    final currency = context.watch<CurrencyCubit>();
    final l10n = AppLocalizations.of(context);
    String money(double inr) =>
        CurrencyFormatter.format(cubit: currency, amountInInr: inr);

    return BlocConsumer<GroupDetailCubit, GroupDetailState>(
      listenWhen: (a, b) => !a.gone && b.gone,
      listener: (context, _) {
        if (context.canPop()) context.pop();
      },
      builder: (context, state) {
        final group = state.group;
        return Scaffold(
          backgroundColor: palette.background,
          floatingActionButton: group == null
              ? null
              : FloatingActionButton.extended(
                  backgroundColor: palette.accent,
                  foregroundColor: palette.onAccent,
                  onPressed: () => _addExpense(context, group),
                  icon: const Icon(Icons.add),
                  label: Text(l10n.groups_addExpense),
                ),
          body: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(24.w, 10.h, 24.w, 0),
                  child: NeuAppBar(
                    title: group?.name ?? l10n.groups_title,
                    onBack: () => context.pop(),
                    trailing: group == null
                        ? null
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                tooltip: l10n.groups_invite,
                                icon: Icon(
                                  Icons.person_add_alt_1_outlined,
                                  color: palette.textDark,
                                ),
                                onPressed: () => _invite(context, group),
                              ),
                              PopupMenuButton<String>(
                                icon: Icon(
                                  Icons.more_vert,
                                  color: palette.textDark,
                                ),
                                onSelected: (v) => switch (v) {
                                  'budget' => _editBudget(context, group),
                                  _ => _leave(context),
                                },
                                itemBuilder: (_) => [
                                  PopupMenuItem(
                                    value: 'budget',
                                    child: Text(l10n.groups_editBudget),
                                  ),
                                  PopupMenuItem(
                                    value: 'leave',
                                    child: Text(l10n.groups_leave),
                                  ),
                                ],
                              ),
                            ],
                          ),
                  ),
                ),
                Expanded(
                  child: state.loading || group == null
                      ? const Center(child: NeuLoading())
                      : ListView(
                          padding: EdgeInsets.fromLTRB(24.w, 20.h, 24.w, 96.h),
                          children: [
                            if (group.monthlyBudget != null) ...[
                              _BudgetCard(
                                spent: state.spentThisMonth,
                                budget: group.monthlyBudget!,
                                money: money,
                              ),
                              SizedBox(height: 16.h),
                            ],
                            _section(palette, l10n.groups_balances),
                            _Balances(state: state, money: money),
                            if (state.suggestions.isNotEmpty) ...[
                              SizedBox(height: 16.h),
                              _section(palette, l10n.groups_settleUp),
                              for (final t in state.suggestions)
                                _TransferRow(
                                  transfer: t,
                                  group: group,
                                  me: state.me,
                                  money: money,
                                  onRecord: () => _settle(context, t),
                                ),
                            ],
                            SizedBox(height: 16.h),
                            _section(palette, l10n.groups_expenses),
                            if (state.expenses.isEmpty)
                              Text(
                                l10n.groups_noExpenses,
                                style: AppTextStyles.manrope(
                                  fontSize: 13.sp,
                                  color: palette.textMuted,
                                ),
                              ),
                            for (final e in state.expenses)
                              _ExpenseRow(
                                expense: e,
                                group: group,
                                me: state.me,
                                money: money,
                                onDelete:
                                    e.createdBy == state.me ||
                                        group.ownerUid == state.me
                                    ? () => _deleteExpense(context, e)
                                    : null,
                              ),
                            if (state.settlements.isNotEmpty) ...[
                              SizedBox(height: 16.h),
                              _section(palette, l10n.groups_payments),
                              for (final s in state.settlements)
                                Padding(
                                  padding: EdgeInsets.symmetric(vertical: 4.h),
                                  child: Text(
                                    l10n.groups_paid(
                                      _who(l10n, group, state.me, s.from),
                                      _who(l10n, group, state.me, s.to),
                                      money(s.amount),
                                    ),
                                    style: AppTextStyles.manrope(
                                      fontSize: 13.sp,
                                      color: palette.textMuted,
                                    ),
                                  ),
                                ),
                            ],
                          ],
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static Widget _section(NeuPalette palette, String text) => Padding(
    padding: EdgeInsets.only(bottom: 8.h),
    child: Text(
      text,
      style: AppTextStyles.manrope(
        fontSize: 15.sp,
        fontWeight: FontWeight.w700,
        color: palette.textDark,
      ),
    ),
  );

  static void _showFailure(BuildContext context, GroupException e) =>
      NeuSnackBar.show(
        context: context,
        message: groupFailureLabel(AppLocalizations.of(context), e.failure),
        type: NeuSnackBarType.error,
      );

  Future<void> _invite(BuildContext context, SpendingGroup group) async {
    final cubit = context.read<GroupDetailCubit>();
    final l10n = AppLocalizations.of(context);
    try {
      final code = await cubit.invite();
      if (!context.mounted) return;
      final palette = context.read<ThemeCubit>().state.palette;
      await NeuBottomSheet.show<void>(
        context: context,
        builder: (sheetContext) => Padding(
          padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 24.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SheetDragHandle(),
              SizedBox(height: 16.h),
              sheetTitle(palette, l10n.groups_invite),
              SizedBox(height: 16.h),
              SelectableText(
                code,
                style: AppTextStyles.manrope(
                  fontSize: 32.sp,
                  fontWeight: FontWeight.w800,
                  color: palette.accent,
                ).copyWith(letterSpacing: 6),
              ),
              SizedBox(height: 8.h),
              Text(
                l10n.groups_inviteHint,
                textAlign: TextAlign.center,
                style: AppTextStyles.manrope(
                  fontSize: 12.sp,
                  color: palette.textMuted,
                ),
              ),
              SizedBox(height: 16.h),
              Row(
                children: [
                  Expanded(
                    child: NeuButton(
                      label: l10n.groups_copy,
                      icon: Icons.copy,
                      variant: NeuButtonVariant.secondary,
                      onTap: () => copyText(code),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: NeuButton(
                      label: l10n.groups_share,
                      icon: Icons.share,
                      onTap: () => SharePlus.instance.share(
                        ShareParams(
                          text: l10n.groups_shareText(group.name, code),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    } on GroupException catch (e) {
      if (context.mounted) _showFailure(context, e);
    }
  }

  Future<void> _editBudget(BuildContext context, SpendingGroup group) async {
    final cubit = context.read<GroupDetailCubit>();
    final currency = context.read<CurrencyCubit>();
    final l10n = AppLocalizations.of(context);
    final budget = TextEditingController(
      text: group.monthlyBudget == null
          ? ''
          : currency.convertFromInr(group.monthlyBudget!).toStringAsFixed(0),
    );
    String? error;
    await NeuBottomSheet.show<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheet) {
          final palette = sheetContext.watch<ThemeCubit>().state.palette;
          Future<void> save() async {
            final text = budget.text.trim();
            double? inr;
            if (text.isNotEmpty) {
              final v = double.tryParse(text);
              if (v == null || v <= 0) {
                setSheet(() => error = l10n.addExpense_validAmount);
                return;
              }
              inr = double.parse(
                currency
                    .convertToInr(
                      amount: v,
                      fromCurrency: currency.state.selected.code,
                    )
                    .toStringAsFixed(2),
              );
            }
            try {
              await cubit.updateBudget(inr);
              if (sheetContext.mounted) Navigator.of(sheetContext).pop();
            } on GroupException catch (e) {
              setSheet(() => error = groupFailureLabel(l10n, e.failure));
            }
          }

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
                  sheetTitle(palette, l10n.groups_editBudget),
                  SizedBox(height: 16.h),
                  NeuTextField(
                    height: 56.h,
                    controller: budget,
                    hint: l10n.groups_budgetHint(
                      currency.state.selected.symbol,
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                  if (error != null) errorText(palette, error!),
                  SizedBox(height: 16.h),
                  SizedBox(
                    width: double.infinity,
                    child: NeuButton(label: l10n.events_save, onTap: save),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _settle(BuildContext context, Transfer t) async {
    final cubit = context.read<GroupDetailCubit>();
    final l10n = AppLocalizations.of(context);
    try {
      final error = await cubit.settle(
        from: t.from,
        to: t.to,
        amount: t.amount,
      );
      if (context.mounted && error == null) {
        NeuSnackBar.show(
          context: context,
          message: l10n.groups_paymentRecorded,
          type: NeuSnackBarType.success,
        );
      }
    } on GroupException catch (e) {
      if (context.mounted) _showFailure(context, e);
    }
  }

  Future<void> _deleteExpense(BuildContext context, GroupExpense e) async {
    final cubit = context.read<GroupDetailCubit>();
    final l10n = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.detail_deleteTransaction),
        content: Text(e.title),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.common_cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.common_delete),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await cubit.deleteExpense(e.id);
    } on GroupException catch (failure) {
      if (context.mounted) _showFailure(context, failure);
    }
  }

  Future<void> _leave(BuildContext context) async {
    final cubit = context.read<GroupDetailCubit>();
    final l10n = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.groups_leave),
        content: Text(l10n.groups_leaveConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.common_cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.groups_leave),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    try {
      final error = await cubit.leave();
      if (!context.mounted) return;
      if (error != null) {
        NeuSnackBar.show(
          context: context,
          message: switch (error) {
            LeaveGroupError.unsettled => l10n.groups_leaveUnsettled,
            LeaveGroupError.ownerWithMembers => l10n.groups_leaveOwner,
          },
          type: NeuSnackBarType.error,
        );
      } else if (context.canPop()) {
        context.pop();
      }
    } on GroupException catch (e) {
      if (context.mounted) _showFailure(context, e);
    }
  }

  Future<void> _addExpense(BuildContext context, SpendingGroup group) {
    final cubit = context.read<GroupDetailCubit>();
    final currency = context.read<CurrencyCubit>();
    final l10n = AppLocalizations.of(context);
    final me = cubit.state.me;
    final title = TextEditingController();
    final amount = TextEditingController();
    final custom = {
      for (final m in group.members) m.uid: TextEditingController(),
    };
    var paidBy = me ?? group.members.first.uid;
    var included = {...group.memberUids};
    var equalSplit = true;
    String? categoryId;
    var addMine = true;
    var saving = false;
    String? error;
    final code = currency.state.selected.code;

    double toInr(double v) => double.parse(
      currency.convertToInr(amount: v, fromCurrency: code).toStringAsFixed(2),
    );

    return NeuBottomSheet.show<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheet) {
          final palette = sheetContext.watch<ThemeCubit>().state.palette;

          Future<void> save() async {
            final value = double.tryParse(amount.text.trim());
            if (value == null || value <= 0) {
              setSheet(() => error = l10n.addExpense_validAmount);
              return;
            }
            final total = toInr(value);
            Map<String, double> shares;
            if (equalSplit) {
              if (included.isEmpty) {
                setSheet(() => error = l10n.groups_errorShares);
                return;
              }
              shares = SplitMath.equal(total, [
                for (final m in group.memberUids)
                  if (included.contains(m)) m,
              ]);
            } else {
              final entered = {
                for (final e in custom.entries)
                  e.key: double.tryParse(e.value.text.trim()) ?? 0,
              };
              final sum = entered.values.fold<double>(0, (s, v) => s + v);
              if ((sum - value).abs() > 0.009) {
                setSheet(() => error = l10n.groups_errorShares);
                return;
              }
              // Convert each share; push any rounding drift onto the payer
              // so the INR shares still sum to the INR total exactly.
              shares = {
                for (final e in entered.entries)
                  if (e.value > 0) e.key: toInr(e.value),
              };
              final drift =
                  SplitMath.toPaise(total) -
                  shares.values.fold<int>(
                    0,
                    (s, v) => s + SplitMath.toPaise(v),
                  );
              if (drift != 0) {
                final key = shares.containsKey(paidBy)
                    ? paidBy
                    : shares.keys.first;
                shares[key] = SplitMath.fromPaise(
                  SplitMath.toPaise(shares[key]!) + drift,
                );
              }
            }
            setSheet(() {
              saving = true;
              error = null;
            });
            try {
              final failure = await cubit.addExpense(
                title: title.text,
                amount: total,
                paidBy: paidBy,
                shares: shares,
                categoryId: categoryId,
                addMyShareToMyExpenses: addMine,
              );
              if (failure != null) {
                setSheet(() {
                  saving = false;
                  error = groupExpenseErrorLabel(l10n, failure);
                });
              } else if (sheetContext.mounted) {
                Navigator.of(sheetContext).pop();
              }
            } on GroupException catch (e) {
              setSheet(() {
                saving = false;
                error = groupFailureLabel(l10n, e.failure);
              });
            }
          }

          String label(GroupMember m) => m.uid == me ? l10n.groups_you : m.name;

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(sheetContext).height * .9,
              ),
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 24.h),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SheetDragHandle(),
                    SizedBox(height: 16.h),
                    sheetTitle(palette, l10n.groups_addExpense),
                    SizedBox(height: 16.h),
                    NeuTextField(
                      height: 56.h,
                      controller: title,
                      hint: l10n.groups_expenseHint,
                      maxLength: 60,
                    ),
                    SizedBox(height: 12.h),
                    NeuTextField(
                      height: 56.h,
                      controller: amount,
                      hint: l10n.groups_amountHint(
                        currency.state.selected.symbol,
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                    SizedBox(height: 16.h),
                    _label(palette, l10n.groups_paidBy),
                    SizedBox(height: 8.h),
                    choiceChips(palette, [
                      for (final m in group.members)
                        (
                          label(m),
                          paidBy == m.uid,
                          () => setSheet(() => paidBy = m.uid),
                        ),
                    ]),
                    SizedBox(height: 16.h),
                    _label(palette, l10n.groups_split),
                    SizedBox(height: 8.h),
                    choiceChips(palette, [
                      (
                        l10n.groups_splitEqual,
                        equalSplit,
                        () => setSheet(() => equalSplit = true),
                      ),
                      (
                        l10n.groups_splitCustom,
                        !equalSplit,
                        () => setSheet(() => equalSplit = false),
                      ),
                    ]),
                    SizedBox(height: 10.h),
                    if (equalSplit)
                      choiceChips(palette, [
                        for (final m in group.members)
                          (
                            '${included.contains(m.uid) ? '✓ ' : ''}${label(m)}',
                            included.contains(m.uid),
                            () => setSheet(() {
                              included = {...included};
                              if (!included.remove(m.uid)) {
                                included.add(m.uid);
                              }
                            }),
                          ),
                      ])
                    else
                      for (final m in group.members)
                        Padding(
                          padding: EdgeInsets.only(bottom: 8.h),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  label(m),
                                  style: AppTextStyles.manrope(
                                    fontSize: 14.sp,
                                    color: palette.textDark,
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 130.w,
                                child: NeuTextField(
                                  height: 48.h,
                                  controller: custom[m.uid]!,
                                  hint: '0',
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    SizedBox(height: 16.h),
                    _label(palette, l10n.groups_category),
                    SizedBox(height: 8.h),
                    choiceChips(palette, [
                      for (final c in ExpenseCategories.all)
                        (
                          '${c.emoji} ${c.labelOf(l10n)}',
                          categoryId == c.id,
                          () => setSheet(
                            () => categoryId = categoryId == c.id ? null : c.id,
                          ),
                        ),
                    ]),
                    if (me != null)
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        value: addMine,
                        activeThumbColor: palette.accent,
                        onChanged: (v) => setSheet(() => addMine = v),
                        title: Text(
                          l10n.groups_addMine,
                          style: AppTextStyles.manrope(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: palette.textDark,
                          ),
                        ),
                        subtitle: Text(
                          l10n.groups_addMineHint,
                          style: AppTextStyles.manrope(
                            fontSize: 12.sp,
                            color: palette.textMuted,
                          ),
                        ),
                      ),
                    if (error != null) errorText(palette, error!),
                    SizedBox(height: 16.h),
                    SizedBox(
                      width: double.infinity,
                      child: NeuButton(
                        label: l10n.groups_addExpense,
                        loading: saving,
                        onTap: saving ? null : save,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  static Widget _label(NeuPalette palette, String text) => Text(
    text,
    style: AppTextStyles.manrope(
      fontSize: 14.sp,
      fontWeight: FontWeight.w600,
      color: palette.textDark,
    ),
  );
}

String _who(AppLocalizations l10n, SpendingGroup g, String? me, String uid) =>
    uid == me ? l10n.groups_you : g.nameOf(uid);

class _BudgetCard extends StatelessWidget {
  const _BudgetCard({
    required this.spent,
    required this.budget,
    required this.money,
  });

  final double spent;
  final double budget;
  final String Function(double) money;

  @override
  Widget build(BuildContext context) {
    final palette = context.watch<ThemeCubit>().state.palette;
    final l10n = AppLocalizations.of(context);
    final ratio = budget <= 0 ? 0.0 : spent / budget;
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: NeuBox.raised(palette, radius: 20.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.groups_thisMonth,
            style: AppTextStyles.manrope(
              fontSize: 12.sp,
              color: palette.textMuted,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            '${money(spent)} / ${money(budget)}',
            style: AppTextStyles.manrope(
              fontSize: 18.sp,
              fontWeight: FontWeight.w700,
              color: palette.textDark,
            ),
          ),
          SizedBox(height: 10.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(6.r),
            child: LinearProgressIndicator(
              value: ratio.clamp(0, 1).toDouble(),
              minHeight: 8.h,
              backgroundColor: palette.textMuted.withValues(alpha: .15),
              color: ratio > 1 ? palette.danger : palette.accent,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            ratio > 1
                ? l10n.groups_overBy(money(spent - budget))
                : l10n.groups_left(money(budget - spent)),
            style: AppTextStyles.manrope(
              fontSize: 12.sp,
              color: ratio > 1 ? palette.danger : palette.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _Balances extends StatelessWidget {
  const _Balances({required this.state, required this.money});

  final GroupDetailState state;
  final String Function(double) money;

  @override
  Widget build(BuildContext context) {
    final palette = context.watch<ThemeCubit>().state.palette;
    final l10n = AppLocalizations.of(context);
    final group = state.group!;
    final balances = state.balances;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: NeuBox.raised(palette, radius: 20.r),
      child: Column(
        children: [
          for (final m in group.members)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 6.h),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _who(l10n, group, state.me, m.uid) +
                          (m.uid == group.ownerUid ? ' ★' : ''),
                      style: AppTextStyles.manrope(
                        fontSize: 14.sp,
                        color: palette.textDark,
                      ),
                    ),
                  ),
                  Builder(
                    builder: (_) {
                      final paise = SplitMath.toPaise(balances[m.uid] ?? 0);
                      final (text, color) = paise == 0
                          ? (l10n.groups_settled, palette.textMuted)
                          : paise > 0
                          ? (
                              l10n.groups_isOwed(money(paise / 100)),
                              palette.success,
                            )
                          : (
                              l10n.groups_owes(money(-paise / 100)),
                              palette.danger,
                            );
                      return Text(
                        text,
                        style: AppTextStyles.manrope(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                          color: color,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _TransferRow extends StatelessWidget {
  const _TransferRow({
    required this.transfer,
    required this.group,
    required this.me,
    required this.money,
    required this.onRecord,
  });

  final Transfer transfer;
  final SpendingGroup group;
  final String? me;
  final String Function(double) money;
  final VoidCallback onRecord;

  @override
  Widget build(BuildContext context) {
    final palette = context.watch<ThemeCubit>().state.palette;
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        children: [
          Expanded(
            child: Text(
              l10n.groups_pays(
                _who(l10n, group, me, transfer.from),
                _who(l10n, group, me, transfer.to),
                money(transfer.amount),
              ),
              style: AppTextStyles.manrope(
                fontSize: 13.sp,
                color: palette.textDark,
              ),
            ),
          ),
          TextButton(
            onPressed: onRecord,
            child: Text(
              l10n.groups_record,
              style: AppTextStyles.manrope(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: palette.accent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpenseRow extends StatelessWidget {
  const _ExpenseRow({
    required this.expense,
    required this.group,
    required this.me,
    required this.money,
    this.onDelete,
  });

  final GroupExpense expense;
  final SpendingGroup group;
  final String? me;
  final String Function(double) money;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final palette = context.watch<ThemeCubit>().state.palette;
    final l10n = AppLocalizations.of(context);
    final myShare = me == null ? null : expense.shares[me];
    final category = expense.categoryId == null
        ? null
        : ExpenseCategories.byId(expense.categoryId!);
    return GestureDetector(
      onLongPress: onDelete,
      child: Container(
        margin: EdgeInsets.only(bottom: 10.h),
        padding: EdgeInsets.all(14.r),
        decoration: NeuBox.raised(palette, radius: 16.r),
        child: Row(
          children: [
            Text(category?.emoji ?? '🧾', style: TextStyle(fontSize: 20.sp)),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    expense.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.manrope(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: palette.textDark,
                    ),
                  ),
                  Text(
                    '${l10n.groups_paidByName(_who(l10n, group, me, expense.paidBy))}'
                    '  ·  ${DateFormat.MMMd(l10n.localeName).format(expense.date)}',
                    style: AppTextStyles.manrope(
                      fontSize: 11.sp,
                      color: palette.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  money(expense.amount),
                  style: AppTextStyles.manrope(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: palette.textDark,
                  ),
                ),
                if (myShare != null)
                  Text(
                    l10n.groups_yourShare(money(myShare)),
                    style: AppTextStyles.manrope(
                      fontSize: 11.sp,
                      color: palette.textMuted,
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
