import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

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
import '../../domain/entities/group.dart';
import '../../domain/repositories/group_repository.dart';
import '../cubit/groups_cubit.dart';
import '../widgets/group_labels.dart';

/// Shared household / roommate / trip budgets.
class GroupsScreen extends StatelessWidget {
  const GroupsScreen({super.key, required this.openGroup});

  /// Navigates to a group's detail screen.
  final void Function(BuildContext context, String groupId) openGroup;

  @override
  Widget build(BuildContext context) {
    final palette = context.watch<ThemeCubit>().state.palette;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: palette.background,
      floatingActionButton: BlocBuilder<GroupsCubit, GroupsState>(
        builder: (context, state) => state.signedIn
            ? FloatingActionButton.extended(
                backgroundColor: palette.accent,
                foregroundColor: palette.onAccent,
                onPressed: () => _create(context),
                icon: const Icon(Icons.group_add_outlined),
                label: Text(l10n.groups_new),
              )
            : const SizedBox.shrink(),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(24.w, 10.h, 24.w, 0),
              child: NeuAppBar(
                title: l10n.groups_title,
                onBack: () => context.pop(),
              ),
            ),
            Expanded(
              child: BlocBuilder<GroupsCubit, GroupsState>(
                builder: (context, state) {
                  if (state.loading) return const Center(child: NeuLoading());
                  if (!state.signedIn) {
                    return _centered(
                      EmptyStateWidget(
                        icon: Text('👥', style: TextStyle(fontSize: 40.sp)),
                        title: l10n.groups_signInNeeded,
                        subtitle: l10n.groups_signInHint,
                      ),
                    );
                  }
                  return ListView(
                    padding: EdgeInsets.fromLTRB(24.w, 20.h, 24.w, 96.h),
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: NeuButton(
                          label: l10n.groups_join,
                          icon: Icons.vpn_key_outlined,
                          variant: NeuButtonVariant.secondary,
                          onTap: () => _join(context),
                        ),
                      ),
                      SizedBox(height: 20.h),
                      if (state.failed)
                        Padding(
                          padding: EdgeInsets.only(bottom: 12.h),
                          child: Text(
                            l10n.groups_network,
                            style: AppTextStyles.manrope(
                              fontSize: 12.sp,
                              color: palette.danger,
                            ),
                          ),
                        ),
                      if (state.groups.isEmpty)
                        EmptyStateWidget(
                          icon: Text('🏠', style: TextStyle(fontSize: 40.sp)),
                          title: l10n.groups_emptyTitle,
                          subtitle: l10n.groups_emptyHint,
                        ),
                      for (final g in state.groups) ...[
                        _GroupCard(
                          group: g,
                          onTap: () => openGroup(context, g.id),
                        ),
                        SizedBox(height: 12.h),
                      ],
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _centered(Widget child) => Center(
    child: Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: child,
    ),
  );

  Future<void> _create(BuildContext context) async {
    final cubit = context.read<GroupsCubit>();
    final currency = context.read<CurrencyCubit>();
    final l10n = AppLocalizations.of(context);
    final name = TextEditingController();
    final budget = TextEditingController();
    var kind = GroupKind.household;
    var saving = false;
    String? error;

    final created = await NeuBottomSheet.show<SpendingGroup>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheet) {
          final palette = sheetContext.watch<ThemeCubit>().state.palette;

          Future<void> save() async {
            if (name.text.trim().isEmpty) {
              setSheet(() => error = l10n.groups_errorName);
              return;
            }
            double? inr;
            if (budget.text.trim().isNotEmpty) {
              final v = double.tryParse(budget.text.trim());
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
            setSheet(() {
              saving = true;
              error = null;
            });
            try {
              final group = await cubit.create(
                name: name.text,
                kind: kind,
                monthlyBudget: inr,
              );
              if (sheetContext.mounted) Navigator.of(sheetContext).pop(group);
            } on GroupException catch (e) {
              setSheet(() {
                saving = false;
                error = groupFailureLabel(l10n, e.failure);
              });
            }
          }

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
                  sheetTitle(palette, l10n.groups_new),
                  SizedBox(height: 16.h),
                  choiceChips(palette, [
                    for (final k in GroupKind.values)
                      (
                        '${k.emoji} ${groupKindLabel(l10n, k)}',
                        kind == k,
                        () => setSheet(() => kind = k),
                      ),
                  ]),
                  SizedBox(height: 16.h),
                  NeuTextField(
                    height: 56.h,
                    controller: name,
                    hint: l10n.groups_nameHint,
                    maxLength: 40,
                  ),
                  SizedBox(height: 12.h),
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
                    child: NeuButton(
                      label: l10n.groups_create,
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
    if (created != null && context.mounted) openGroup(context, created.id);
  }

  Future<void> _join(BuildContext context) async {
    final cubit = context.read<GroupsCubit>();
    final l10n = AppLocalizations.of(context);
    final code = TextEditingController();
    var joining = false;
    String? error;

    final joined = await NeuBottomSheet.show<SpendingGroup>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheet) {
          final palette = sheetContext.watch<ThemeCubit>().state.palette;

          Future<void> join() async {
            if (code.text.trim().length != 6) {
              setSheet(() => error = l10n.groups_inviteNotFound);
              return;
            }
            setSheet(() {
              joining = true;
              error = null;
            });
            try {
              final group = await cubit.join(code.text);
              if (sheetContext.mounted) Navigator.of(sheetContext).pop(group);
            } on GroupException catch (e) {
              setSheet(() {
                joining = false;
                error = groupFailureLabel(l10n, e.failure);
              });
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
                  sheetTitle(palette, l10n.groups_join),
                  SizedBox(height: 4.h),
                  Text(
                    l10n.groups_joinHint,
                    style: AppTextStyles.manrope(
                      fontSize: 12.sp,
                      color: palette.textMuted,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  NeuTextField(
                    height: 56.h,
                    controller: code,
                    hint: 'ABC234',
                    maxLength: 6,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => join(),
                  ),
                  if (error != null) errorText(palette, error!),
                  SizedBox(height: 16.h),
                  SizedBox(
                    width: double.infinity,
                    child: NeuButton(
                      label: l10n.groups_joinButton,
                      loading: joining,
                      onTap: joining ? null : join,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
    if (joined != null && context.mounted) openGroup(context, joined.id);
  }
}

class _GroupCard extends StatelessWidget {
  const _GroupCard({required this.group, required this.onTap});

  final SpendingGroup group;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.watch<ThemeCubit>().state.palette;
    final currency = context.watch<CurrencyCubit>();
    final l10n = AppLocalizations.of(context);
    final budget = group.monthlyBudget;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16.r),
        decoration: NeuBox.raised(palette, radius: 20.r),
        child: Row(
          children: [
            Text(group.kind.emoji, style: TextStyle(fontSize: 24.sp)),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    group.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.manrope(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w600,
                      color: palette.textDark,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    [
                      l10n.groups_memberCount(group.members.length),
                      if (budget != null)
                        l10n.groups_budgetPerMonth(
                          CurrencyFormatter.format(
                            cubit: currency,
                            amountInInr: budget,
                          ),
                        ),
                    ].join('  ·  '),
                    style: AppTextStyles.manrope(
                      fontSize: 12.sp,
                      color: palette.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: palette.textMuted, size: 20.sp),
          ],
        ),
      ),
    );
  }
}

// ── Small shared sheet helpers ──────────────────────────────────────────

Widget sheetTitle(NeuPalette palette, String text) => Text(
  text,
  style: AppTextStyles.manrope(
    fontSize: 18.sp,
    fontWeight: FontWeight.bold,
    color: palette.textDark,
  ),
);

Widget errorText(NeuPalette palette, String text) => Padding(
  padding: EdgeInsets.only(top: 8.h),
  child: Text(
    text,
    style: AppTextStyles.manrope(fontSize: 12.sp, color: palette.danger),
  ),
);

Widget choiceChips(
  NeuPalette palette,
  List<(String, bool, VoidCallback)> items,
) => Wrap(
  spacing: 8.w,
  runSpacing: 8.h,
  children: [
    for (final (label, selected, onTap) in items)
      GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
          decoration: NeuBox.raised(
            palette,
            radius: 12.r,
            bgColor: selected ? palette.accent : palette.background,
          ),
          child: Text(
            label,
            style: AppTextStyles.manrope(
              fontSize: 13.sp,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              color: selected ? palette.onAccent : palette.textDark,
            ),
          ),
        ),
      ),
  ],
);

/// Copies [text] and confirms with a light haptic.
Future<void> copyText(String text) async {
  await Clipboard.setData(ClipboardData(text: text));
  await HapticFeedback.selectionClick();
}
