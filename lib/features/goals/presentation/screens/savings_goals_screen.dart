import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/neumorphic_styles.dart';
import '../../../../core/theme/theme_cubit.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/neu_app_bar.dart';
import '../../../../core/widgets/neu_bottom_sheet.dart';
import '../../../../core/widgets/neu_button.dart';
import '../../../../core/widgets/neu_loading.dart';
import '../../../../core/widgets/neu_text_field.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../currency/presentation/cubit/currency_cubit.dart';
import '../../../currency/presentation/util/currency_formatter.dart';
import '../../domain/entities/savings_goal.dart';
import '../../domain/services/goal_progress.dart';
import '../cubit/savings_goals_cubit.dart';

const _goalEmojis = [
  '🎯',
  '✈️',
  '🏖️',
  '🏠',
  '🚗',
  '💍',
  '🎓',
  '📱',
  '💻',
  '🏍️',
  '🎁',
  '🛟',
];

class SavingsGoalsScreen extends StatelessWidget {
  const SavingsGoalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = context.watch<ThemeCubit>().state.palette;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: palette.background,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: palette.accent,
        foregroundColor: palette.onAccent,
        onPressed: () => _showCreateSheet(context),
        icon: const Icon(Icons.add),
        label: Text(l10n.goals_new),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(24.w, 10.h, 24.w, 0),
              child: NeuAppBar(
                title: l10n.goals_title,
                onBack: () => context.pop(),
              ),
            ),
            Expanded(
              child: BlocBuilder<SavingsGoalsCubit, SavingsGoalsState>(
                builder: (context, state) {
                  if (state.loading) return const Center(child: NeuLoading());
                  if (state.goals.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24.w),
                        child: EmptyStateWidget(
                          icon: Text('🎯', style: TextStyle(fontSize: 40.sp)),
                          title: l10n.goals_emptyTitle,
                          subtitle: l10n.goals_emptyHint,
                        ),
                      ),
                    );
                  }
                  return ListView.separated(
                    padding: EdgeInsets.fromLTRB(24.w, 20.h, 24.w, 96.h),
                    itemCount: state.goals.length,
                    separatorBuilder: (_, _) => SizedBox(height: 12.h),
                    itemBuilder: (context, i) =>
                        _GoalCard(goal: state.goals[i]),
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

class _GoalCard extends StatelessWidget {
  const _GoalCard({required this.goal});

  final SavingsGoal goal;

  @override
  Widget build(BuildContext context) {
    final palette = context.watch<ThemeCubit>().state.palette;
    final currency = context.watch<CurrencyCubit>();
    final l10n = AppLocalizations.of(context);
    final progress = GoalProgress.of(goal, DateTime.now());
    String money(double inr) =>
        CurrencyFormatter.format(cubit: currency, amountInInr: inr);

    final status = switch (progress.pace) {
      GoalPace.complete => l10n.goals_complete,
      GoalPace.overdue => l10n.goals_overdue,
      GoalPace.noDeadline => l10n.goals_remaining(money(progress.remaining)),
      GoalPace.onTrack || GoalPace.behind => l10n.goals_perDay(
        money(progress.perDay ?? 0),
        progress.daysLeft ?? 0,
      ),
    };
    final statusColor = switch (progress.pace) {
      GoalPace.complete || GoalPace.onTrack => palette.success,
      GoalPace.behind || GoalPace.overdue => palette.danger,
      GoalPace.noDeadline => palette.textMuted,
    };

    return GestureDetector(
      onTap: () => _showGoalActions(context, goal),
      child: Container(
        padding: EdgeInsets.all(16.r),
        decoration: NeuBox.raised(palette, radius: 20.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(goal.emoji, style: TextStyle(fontSize: 22.sp)),
                SizedBox(width: 10.w),
                Expanded(
                  child: Text(
                    goal.name,
                    style: AppTextStyles.manrope(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w600,
                      color: palette.textDark,
                    ),
                  ),
                ),
                Text(
                  '${progress.percent.round()}%',
                  style: AppTextStyles.manrope(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: palette.accent,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            ClipRRect(
              borderRadius: BorderRadius.circular(8.r),
              child: LinearProgressIndicator(
                value: progress.percent / 100,
                minHeight: 8.h,
                backgroundColor: palette.textMuted.withValues(alpha: .15),
                valueColor: AlwaysStoppedAnimation(palette.accent),
              ),
            ),
            SizedBox(height: 10.h),
            Text(
              l10n.goals_savedOf(money(progress.saved), money(goal.target)),
              style: AppTextStyles.manrope(
                fontSize: 12.sp,
                color: palette.textDark,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              status,
              style: AppTextStyles.manrope(fontSize: 12.sp, color: statusColor),
            ),
            if (goal.targetDate != null) ...[
              SizedBox(height: 2.h),
              Text(
                l10n.goals_by(
                  DateFormat.yMMMd(l10n.localeName).format(goal.targetDate!),
                ),
                style: AppTextStyles.manrope(
                  fontSize: 11.sp,
                  color: palette.textMuted,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Parses a display-currency amount and converts it to INR.
double? _toInr(BuildContext context, String text) {
  final value = double.tryParse(text.trim());
  if (value == null) return null;
  final currency = context.read<CurrencyCubit>();
  return double.parse(
    currency
        .convertToInr(amount: value, fromCurrency: currency.state.selected.code)
        .toStringAsFixed(2),
  );
}

Widget _sheetTitle(NeuPalette palette, String text) => Text(
  text,
  style: AppTextStyles.manrope(
    fontSize: 18.sp,
    fontWeight: FontWeight.bold,
    color: palette.textDark,
  ),
);

Future<void> _showGoalActions(BuildContext context, SavingsGoal goal) {
  final cubit = context.read<SavingsGoalsCubit>();
  final palette = context.read<ThemeCubit>().state.palette;
  final l10n = AppLocalizations.of(context);
  final amount = TextEditingController();
  String? error;

  return NeuBottomSheet.show<void>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => StatefulBuilder(
      builder: (sheetContext, setSheetState) {
        Future<void> submit(int sign) async {
          final inr = _toInr(sheetContext, amount.text);
          if (inr == null || inr <= 0) {
            setSheetState(() => error = l10n.addExpense_validAmount);
            return;
          }
          final message = await cubit.contribute(goal.id, sign * inr);
          if (message != null) {
            setSheetState(() => error = message);
          } else if (sheetContext.mounted) {
            Navigator.of(sheetContext).pop();
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
                _sheetTitle(palette, '${goal.emoji} ${goal.name}'),
                SizedBox(height: 16.h),
                NeuTextField(
                  height: 56.h,
                  controller: amount,
                  hint: l10n.goals_amountHint,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
                if (error != null) ...[
                  SizedBox(height: 8.h),
                  Text(
                    error!,
                    style: AppTextStyles.manrope(
                      fontSize: 12.sp,
                      color: palette.danger,
                    ),
                  ),
                ],
                SizedBox(height: 16.h),
                Row(
                  children: [
                    Expanded(
                      child: NeuButton(
                        label: l10n.goals_addMoney,
                        onTap: () => submit(1),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: NeuButton(
                        label: l10n.goals_withdraw,
                        variant: NeuButtonVariant.secondary,
                        onTap: () => submit(-1),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                Center(
                  child: TextButton(
                    onPressed: () async {
                      await cubit.delete(goal.id);
                      if (sheetContext.mounted) {
                        Navigator.of(sheetContext).pop();
                      }
                    },
                    child: Text(
                      l10n.goals_delete,
                      style: AppTextStyles.manrope(color: palette.danger),
                    ),
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

Future<void> _showCreateSheet(BuildContext context) {
  final cubit = context.read<SavingsGoalsCubit>();
  final palette = context.read<ThemeCubit>().state.palette;
  final l10n = AppLocalizations.of(context);
  final name = TextEditingController();
  final target = TextEditingController();
  final initial = TextEditingController();
  var emoji = _goalEmojis.first;
  DateTime? deadline;
  String? error;
  var saving = false;

  return NeuBottomSheet.show<void>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => StatefulBuilder(
      builder: (sheetContext, setSheetState) {
        Future<void> pickDate() async {
          final now = DateTime.now();
          final picked = await showDatePicker(
            context: sheetContext,
            initialDate: deadline ?? DateTime(now.year, now.month + 3, now.day),
            firstDate: now,
            lastDate: DateTime(now.year + 30),
          );
          if (picked != null) setSheetState(() => deadline = picked);
        }

        Future<void> save() async {
          final targetInr = _toInr(sheetContext, target.text);
          final initialInr = initial.text.trim().isEmpty
              ? 0.0
              : _toInr(sheetContext, initial.text);
          if (targetInr == null || initialInr == null) {
            setSheetState(() => error = l10n.addExpense_validAmount);
            return;
          }
          setSheetState(() => saving = true);
          final message = await cubit.create(
            name: name.text,
            emoji: emoji,
            target: targetInr,
            targetDate: deadline,
            initialAmount: initialInr,
          );
          if (message != null) {
            setSheetState(() {
              saving = false;
              error = message;
            });
          } else if (sheetContext.mounted) {
            Navigator.of(sheetContext).pop();
          }
        }

        final numeric = [
          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
        ];

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
                _sheetTitle(palette, l10n.goals_new),
                SizedBox(height: 16.h),
                Wrap(
                  spacing: 8.w,
                  runSpacing: 8.h,
                  children: [
                    for (final e in _goalEmojis)
                      GestureDetector(
                        onTap: () => setSheetState(() => emoji = e),
                        child: Container(
                          width: 40.w,
                          height: 40.w,
                          alignment: Alignment.center,
                          decoration: NeuBox.raised(
                            palette,
                            radius: 12.r,
                            bgColor: emoji == e
                                ? palette.accent
                                : palette.background,
                          ),
                          child: Text(e, style: TextStyle(fontSize: 18.sp)),
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 16.h),
                NeuTextField(
                  height: 56.h,
                  controller: name,
                  hint: l10n.goals_nameHint,
                  maxLength: 40,
                ),
                SizedBox(height: 12.h),
                TextField(
                  controller: target,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: numeric,
                  decoration: InputDecoration(
                    labelText: l10n.goals_targetLabel(
                      context.read<CurrencyCubit>().state.selected.symbol,
                    ),
                  ),
                ),
                SizedBox(height: 12.h),
                TextField(
                  controller: initial,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: numeric,
                  decoration: InputDecoration(
                    labelText: l10n.goals_initialLabel,
                  ),
                ),
                SizedBox(height: 12.h),
                OutlinedButton.icon(
                  onPressed: pickDate,
                  icon: const Icon(Icons.event_outlined),
                  label: Text(
                    deadline == null
                        ? l10n.goals_pickDate
                        : l10n.goals_by(
                            DateFormat.yMMMd(l10n.localeName).format(deadline!),
                          ),
                  ),
                ),
                if (error != null) ...[
                  SizedBox(height: 8.h),
                  Text(
                    error!,
                    style: AppTextStyles.manrope(
                      fontSize: 12.sp,
                      color: palette.danger,
                    ),
                  ),
                ],
                SizedBox(height: 20.h),
                SizedBox(
                  width: double.infinity,
                  child: NeuButton(
                    label: l10n.common_save,
                    loading: saving,
                    onTap: saving ? null : save,
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
