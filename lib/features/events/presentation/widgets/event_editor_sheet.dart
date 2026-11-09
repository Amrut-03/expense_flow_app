import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/expense_category.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/neumorphic_styles.dart';
import '../../../../core/theme/theme_cubit.dart';
import '../../../../core/widgets/neu_bottom_sheet.dart';
import '../../../../core/widgets/neu_button.dart';
import '../../../../core/widgets/neu_text_field.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../currency/presentation/cubit/currency_cubit.dart';
import '../../domain/entities/spending_event.dart';
import '../cubit/spending_events_cubit.dart';
import 'event_labels.dart';

const _emojis = {
  SpendingEventKind.festival: ['🪔', '🎆', '🎨', '🪁', '🌙', '🎄', '🐘'],
  SpendingEventKind.wedding: ['💍', '💒', '👰', '🎊'],
  SpendingEventKind.trip: ['✈️', '🏖️', '🏔️', '🚆', '🚗', '🛕'],
  SpendingEventKind.other: ['🎉', '🎂', '🏠', '🎓', '🛍️'],
};

/// Create or edit an event / trip.
abstract final class EventEditorSheet {
  static Future<void> show(BuildContext context, {SpendingEvent? existing}) {
    final cubit = context.read<SpendingEventsCubit>();
    final currency = context.read<CurrencyCubit>();
    final l10n = AppLocalizations.of(context);

    final name = TextEditingController(text: existing?.name ?? '');
    final budget = TextEditingController(
      text: existing == null
          ? ''
          : currency.convertFromInr(existing.budget).toStringAsFixed(0),
    );
    var kind = existing?.kind ?? SpendingEventKind.festival;
    var emoji = existing?.emoji ?? kind.defaultEmoji;
    final today = DateUtils.dateOnly(DateTime.now());
    var range = existing == null
        ? DateTimeRange(start: today, end: today.add(const Duration(days: 6)))
        : DateTimeRange(start: existing.startDate, end: existing.endDate);
    var categories = {...?existing?.categoryIds};
    String? tripCurrency = existing?.currency;
    bool? separate = existing?.separateFromBudgets;
    String? error;
    var saving = false;

    final rates = currency.state.rates;
    final currencies = [
      for (final code in tripCurrencies)
        if (rates.isEmpty || rates.containsKey(code)) code,
    ];

    return NeuBottomSheet.show<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheet) {
          final palette = sheetContext.watch<ThemeCubit>().state.palette;
          final isTrip = kind == SpendingEventKind.trip;
          final separateValue = separate ?? isTrip;

          Future<void> pickDates() async {
            final picked = await showDateRangePicker(
              context: sheetContext,
              initialDateRange: range,
              firstDate: DateTime(today.year - 1),
              lastDate: DateTime(today.year + 2),
            );
            if (picked != null) setSheet(() => range = picked);
          }

          Future<void> save() async {
            final value = double.tryParse(budget.text.trim());
            if (value == null || value <= 0) {
              setSheet(() => error = l10n.addExpense_validAmount);
              return;
            }
            final inr = currency.convertToInr(
              amount: value,
              fromCurrency: currency.state.selected.code,
            );
            setSheet(() => saving = true);
            final failure = await cubit.saveEvent(
              id: existing?.id,
              name: name.text,
              emoji: emoji,
              kind: kind,
              startDate: range.start,
              endDate: range.end,
              budget: double.parse(inr.toStringAsFixed(2)),
              categoryIds: isTrip ? const {} : categories,
              currency: isTrip ? tripCurrency : null,
              separateFromBudgets: separateValue,
            );
            if (failure != null) {
              setSheet(() {
                saving = false;
                error = eventErrorLabel(l10n, failure);
              });
            } else if (sheetContext.mounted) {
              Navigator.of(sheetContext).pop();
            }
          }

          final dateFormat = DateFormat.MMMd(l10n.localeName);
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
                  Text(
                    existing == null ? l10n.events_new : l10n.events_edit,
                    style: AppTextStyles.manrope(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: palette.textDark,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  _chips(palette, [
                    for (final k in SpendingEventKind.values)
                      (
                        '${k.defaultEmoji} ${eventKindLabel(l10n, k)}',
                        kind == k,
                        () => setSheet(() {
                          kind = k;
                          emoji = k.defaultEmoji;
                        }),
                      ),
                  ]),
                  SizedBox(height: 12.h),
                  _chips(palette, [
                    for (final e in _emojis[kind]!)
                      (e, emoji == e, () => setSheet(() => emoji = e)),
                  ]),
                  SizedBox(height: 16.h),
                  NeuTextField(
                    height: 56.h,
                    controller: name,
                    hint: isTrip
                        ? l10n.events_nameHintTrip
                        : l10n.events_nameHint,
                    maxLength: 40,
                  ),
                  SizedBox(height: 12.h),
                  NeuTextField(
                    height: 56.h,
                    controller: budget,
                    hint: l10n.events_budgetHint(
                      currency.state.selected.symbol,
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  GestureDetector(
                    onTap: pickDates,
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 16.h,
                      ),
                      decoration: NeuBox.raised(palette, radius: 14.r),
                      child: Row(
                        children: [
                          Icon(
                            Icons.date_range,
                            color: palette.textMuted,
                            size: 18.sp,
                          ),
                          SizedBox(width: 10.w),
                          Text(
                            '${dateFormat.format(range.start)} – '
                            '${dateFormat.format(range.end)}  ·  '
                            '${l10n.events_days(range.duration.inDays + 1)}',
                            style: AppTextStyles.manrope(
                              fontSize: 14.sp,
                              color: palette.textDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 16.h),
                  if (isTrip) ...[
                    _label(palette, l10n.events_tripCurrency),
                    SizedBox(height: 8.h),
                    _chips(palette, [
                      (
                        '₹ INR',
                        tripCurrency == null,
                        () => setSheet(() => tripCurrency = null),
                      ),
                      for (final code in currencies)
                        (
                          code,
                          tripCurrency == code,
                          () => setSheet(() => tripCurrency = code),
                        ),
                    ]),
                    SizedBox(height: 6.h),
                    _hint(palette, l10n.events_tripCurrencyHint),
                  ] else ...[
                    _label(palette, l10n.events_categories),
                    SizedBox(height: 8.h),
                    _chips(palette, [
                      (
                        l10n.events_allCategories,
                        categories.isEmpty,
                        () => setSheet(() => categories = {}),
                      ),
                      for (final c in ExpenseCategories.all)
                        (
                          '${c.emoji} ${c.labelOf(l10n)}',
                          categories.contains(c.id),
                          () => setSheet(() {
                            categories = {...categories};
                            if (!categories.remove(c.id)) {
                              categories.add(c.id);
                            }
                          }),
                        ),
                    ]),
                  ],
                  SizedBox(height: 12.h),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: separateValue,
                    activeThumbColor: palette.accent,
                    onChanged: (v) => setSheet(() => separate = v),
                    title: Text(
                      l10n.events_separate,
                      style: AppTextStyles.manrope(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: palette.textDark,
                      ),
                    ),
                    subtitle: Text(
                      l10n.events_separateHint,
                      style: AppTextStyles.manrope(
                        fontSize: 12.sp,
                        color: palette.textMuted,
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
                  SizedBox(height: 16.h),
                  SizedBox(
                    width: double.infinity,
                    child: NeuButton(
                      label: l10n.events_save,
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

  static Widget _label(NeuPalette palette, String text) => Text(
    text,
    style: AppTextStyles.manrope(
      fontSize: 14.sp,
      fontWeight: FontWeight.w600,
      color: palette.textDark,
    ),
  );

  static Widget _hint(NeuPalette palette, String text) => Text(
    text,
    style: AppTextStyles.manrope(fontSize: 11.sp, color: palette.textMuted),
  );

  static Widget _chips(
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
}
