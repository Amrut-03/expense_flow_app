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
import '../../domain/services/event_progress.dart';
import '../cubit/spending_events_cubit.dart';
import '../widgets/event_editor_sheet.dart';
import '../widgets/event_labels.dart';

/// Festival / wedding budgets and trips.
class EventsScreen extends StatelessWidget {
  const EventsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = context.watch<ThemeCubit>().state.palette;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: palette.background,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: palette.accent,
        foregroundColor: palette.onAccent,
        onPressed: () => EventEditorSheet.show(context),
        icon: const Icon(Icons.add),
        label: Text(l10n.events_new),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(24.w, 10.h, 24.w, 0),
              child: NeuAppBar(
                title: l10n.events_title,
                onBack: () => context.pop(),
              ),
            ),
            Expanded(
              child: BlocBuilder<SpendingEventsCubit, SpendingEventsState>(
                builder: (context, state) {
                  if (state.loading) return const Center(child: NeuLoading());
                  if (state.events.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24.w),
                        child: EmptyStateWidget(
                          icon: Text('🪔', style: TextStyle(fontSize: 40.sp)),
                          title: l10n.events_emptyTitle,
                          subtitle: l10n.events_emptyHint,
                        ),
                      ),
                    );
                  }
                  return ListView.separated(
                    padding: EdgeInsets.fromLTRB(24.w, 20.h, 24.w, 96.h),
                    itemCount: state.events.length,
                    separatorBuilder: (_, _) => SizedBox(height: 12.h),
                    itemBuilder: (context, i) => EventCard(
                      progress: state.events[i],
                      onTap: () => _openDetail(context, state.events[i]),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  static void _openDetail(BuildContext context, EventProgress progress) {
    final cubit = context.read<SpendingEventsCubit>();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BlocProvider.value(
          value: cubit,
          child: EventDetailScreen(eventId: progress.event.id),
        ),
      ),
    );
  }
}

/// Compact progress card, also used on the dashboard.
class EventCard extends StatelessWidget {
  const EventCard({super.key, required this.progress, this.onTap});

  final EventProgress progress;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.watch<ThemeCubit>().state.palette;
    final currency = context.watch<CurrencyCubit>();
    final l10n = AppLocalizations.of(context);
    final event = progress.event;
    String money(double inr) =>
        CurrencyFormatter.format(cubit: currency, amountInInr: inr);

    final barColor = progress.isOver || progress.projectedOver
        ? palette.danger
        : palette.accent;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16.r),
        decoration: NeuBox.raised(palette, radius: 20.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(event.emoji, style: TextStyle(fontSize: 22.sp)),
                SizedBox(width: 10.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.manrope(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w600,
                          color: palette.textDark,
                        ),
                      ),
                      Text(
                        eventStatusLabel(l10n, progress),
                        style: AppTextStyles.manrope(
                          fontSize: 11.sp,
                          color: palette.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${(progress.fraction * 100).round()}%',
                  style: AppTextStyles.manrope(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: barColor,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            ClipRRect(
              borderRadius: BorderRadius.circular(8.r),
              child: LinearProgressIndicator(
                value: progress.fraction.clamp(0, 1).toDouble(),
                minHeight: 8.h,
                backgroundColor: palette.textMuted.withValues(alpha: .15),
                valueColor: AlwaysStoppedAnimation(barColor),
              ),
            ),
            SizedBox(height: 10.h),
            Text(
              l10n.events_spentOf(money(progress.spent), money(event.budget)),
              style: AppTextStyles.manrope(
                fontSize: 12.sp,
                color: palette.textDark,
              ),
            ),
            if (progress.spentInTripCurrency != null)
              Text(
                '≈ ${_foreign(progress.spentInTripCurrency!, event.currency!)}',
                style: AppTextStyles.manrope(
                  fontSize: 11.sp,
                  color: palette.textMuted,
                ),
              ),
            if (progress.status == EventStatus.active) ...[
              SizedBox(height: 4.h),
              Text(
                progress.isOver
                    ? l10n.events_over(money(-progress.remaining))
                    : progress.projectedOver
                    ? l10n.events_projectedOver(money(progress.projectedTotal!))
                    : l10n.events_perDayLeft(
                        money(progress.perDayLeft),
                        progress.daysLeft,
                      ),
                style: AppTextStyles.manrope(
                  fontSize: 12.sp,
                  color: progress.isOver || progress.projectedOver
                      ? palette.danger
                      : palette.success,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

String _foreign(double amount, String code) =>
    NumberFormat.simpleCurrency(name: code).format(amount);

String eventStatusLabel(AppLocalizations l10n, EventProgress p) {
  final f = DateFormat.MMMd(l10n.localeName);
  final kind = eventKindLabel(l10n, p.event.kind);
  return switch (p.status) {
    EventStatus.active => '$kind · ${l10n.events_daysLeft(p.daysLeft)}',
    EventStatus.upcoming =>
      '$kind · ${l10n.events_starts(f.format(p.event.startDate))}',
    EventStatus.ended =>
      '$kind · ${l10n.events_ended(f.format(p.event.endDate))}',
  };
}

class EventDetailScreen extends StatelessWidget {
  const EventDetailScreen({super.key, required this.eventId});

  final String eventId;

  @override
  Widget build(BuildContext context) {
    final palette = context.watch<ThemeCubit>().state.palette;
    final currency = context.watch<CurrencyCubit>();
    final l10n = AppLocalizations.of(context);
    String money(double inr) =>
        CurrencyFormatter.format(cubit: currency, amountInInr: inr);

    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        child: BlocBuilder<SpendingEventsCubit, SpendingEventsState>(
          builder: (context, state) {
            final progress = state.byId(eventId);
            if (progress == null) {
              return const Center(child: NeuLoading());
            }
            final event = progress.event;
            final categories = progress.byCategory.entries.toList()
              ..sort((a, b) => b.value.compareTo(a.value));

            return Column(
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(24.w, 10.h, 24.w, 0),
                  child: NeuAppBar(
                    title: event.name,
                    onBack: () => Navigator.of(context).pop(),
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.fromLTRB(24.w, 20.h, 24.w, 24.h),
                    children: [
                      EventCard(progress: progress),
                      if (event.separateFromBudgets) ...[
                        SizedBox(height: 8.h),
                        Text(
                          l10n.events_separateNote,
                          style: AppTextStyles.manrope(
                            fontSize: 11.sp,
                            color: palette.textMuted,
                          ),
                        ),
                      ],
                      SizedBox(height: 20.h),
                      if (categories.isNotEmpty) ...[
                        _heading(palette, l10n.events_byCategory),
                        SizedBox(height: 10.h),
                        for (final entry in categories)
                          _row(palette, () {
                            final c = ExpenseCategories.byId(entry.key);
                            return '${c.emoji}  ${c.labelOf(l10n)}';
                          }(), money(entry.value)),
                        SizedBox(height: 20.h),
                      ],
                      _heading(
                        palette,
                        l10n.events_transactions(progress.expenses.length),
                      ),
                      SizedBox(height: 10.h),
                      if (progress.expenses.isEmpty)
                        Text(
                          l10n.events_noTransactions,
                          style: AppTextStyles.manrope(
                            fontSize: 12.sp,
                            color: palette.textMuted,
                          ),
                        ),
                      for (final e in progress.expenses)
                        GestureDetector(
                          onTap: () =>
                              context.push('/transaction-detail', extra: e),
                          child: _row(
                            palette,
                            '${ExpenseCategories.byId(e.categoryId).emoji}  '
                            '${e.title ?? e.merchant ?? ''}',
                            e.isForeignCurrency
                                ? '${_foreign(e.paidAmount, e.currency)} · '
                                      '${money(e.amount)}'
                                : money(e.amount),
                            sub: DateFormat.MMMd(
                              l10n.localeName,
                            ).format(e.date),
                          ),
                        ),
                      SizedBox(height: 24.h),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => EventEditorSheet.show(
                                context,
                                existing: event,
                              ),
                              icon: const Icon(Icons.edit_outlined),
                              label: Text(l10n.events_edit),
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: palette.danger,
                              ),
                              onPressed: () => _confirmDelete(context),
                              icon: const Icon(Icons.delete_outline),
                              label: Text(l10n.events_delete),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<SpendingEventsCubit>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.events_delete),
        content: Text(l10n.events_deleteConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.events_delete),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    await cubit.deleteEvent(eventId);
    if (context.mounted) Navigator.of(context).pop();
  }

  Widget _heading(NeuPalette palette, String text) => Text(
    text,
    style: AppTextStyles.manrope(
      fontSize: 15.sp,
      fontWeight: FontWeight.bold,
      color: palette.textDark,
    ),
  );

  Widget _row(NeuPalette palette, String label, String value, {String? sub}) =>
      Padding(
        padding: EdgeInsets.symmetric(vertical: 6.h),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.manrope(
                      fontSize: 13.sp,
                      color: palette.textDark,
                    ),
                  ),
                  if (sub != null)
                    Text(
                      sub,
                      style: AppTextStyles.manrope(
                        fontSize: 11.sp,
                        color: palette.textMuted,
                      ),
                    ),
                ],
              ),
            ),
            Text(
              value,
              style: AppTextStyles.manrope(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: palette.textDark,
              ),
            ),
          ],
        ),
      );
}
