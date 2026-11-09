import 'package:intl/intl.dart';
import 'package:expense_flow_app/core/theme/app_text_styles.dart';
import 'package:expense_flow_app/core/theme/neumorphic_styles.dart';
import 'package:expense_flow_app/core/widgets/neu_icon_button.dart';
import 'package:expense_flow_app/core/widgets/neu_snack_bar.dart';
import 'package:expense_flow_app/core/widgets/neu_text_field.dart';
import 'package:expense_flow_app/features/expense/presentation/widgets/amount_input.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/expense_category.dart';
import '../../../../core/constants/note_limits.dart';
import '../../../../core/constants/payment_methods.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_cubit.dart';
import '../../../../core/widgets/concave_decoration.dart';
import '../../../../core/widgets/tab_reveal.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../categories/domain/services/category_suggester.dart';
import '../../../categories/presentation/widgets/category_editor_sheet.dart';
import '../../../currency/presentation/cubit/currency_cubit.dart';
import '../../../events/domain/entities/spending_event.dart';
import '../../../events/domain/repositories/spending_event_repository.dart';
import '../../../events/domain/services/event_progress.dart';
import '../../../events/presentation/widgets/event_tag_picker.dart';
import '../../../receipt_scan/domain/entities/receipt_draft.dart';
import '../../../receipt_scan/domain/usecases/scan_receipt_usecase.dart';
import '../../../receipt_scan/presentation/widgets/receipt_scan_sheet.dart';
import '../../../recurring/domain/entities/recurring_expense_entity.dart';
import '../../../recurring/presentation/recurrence_labels.dart';
import '../../../tax/domain/entities/tax_section.dart';
import '../../../tax/domain/services/tax_tag_suggester.dart';
import '../../../tax/presentation/widgets/tax_tag_picker.dart';
import '../../../../core/di/injection_container.dart';
import '../../../settings/presentation/cubit/locale_cubit.dart';
import '../../../voice_entry/domain/entities/voice_expense_draft.dart';
import '../../../voice_entry/presentation/cubit/voice_entry_cubit.dart';
import '../../../voice_entry/presentation/widgets/voice_entry_sheet.dart';
import '../bloc/expense_bloc.dart';
import '../bloc/expense_event.dart';
import '../bloc/expense_state.dart';
import '../widgets/category_tile.dart';

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _amountController = TextEditingController();
  final _titleController = TextEditingController();
  final _merchantController = TextEditingController();
  final _noteController = TextEditingController();
  bool _isSaving = false;
  String? _selectedCategoryId;
  String? _paymentMethod;
  RecurrenceFrequency? _repeat;
  TaxSection? _taxTag;
  bool _wasTicking = true;

  /// True once the user picks a tax tag by hand; suggestions stop then.
  bool _taxTouched = false;
  bool _taxSuggested = false;

  /// Events/trips running today, offered in the "Part of" picker.
  List<SpendingEvent> _activeEvents = _loadActiveEvents();

  static List<SpendingEvent> _loadActiveEvents() => [
    for (final e in sl<SpendingEventRepository>().getAll())
      if (e.isActiveOn(DateTime.now())) e,
  ];
  SpendingEvent? _pickedEvent;
  bool _eventTouched = false;

  /// The chosen event, or the automatic suggestion (active trip first,
  /// else an active event covering the selected category).
  SpendingEvent? get _event => _eventTouched
      ? _pickedEvent
      : EventMatcher.suggest(
          _activeEvents,
          when: DateTime.now(),
          categoryId: _selectedCategoryId,
        );

  /// Foreign currency of the selected trip, when amounts are entered in it.
  String? get _tripCurrency {
    final e = _event;
    return e != null && e.isTrip ? e.currency : null;
  }

  /// True once the user picks a category by hand; suggestions stop then.
  bool _categoryTouched = false;
  bool _categorySuggested = false;

  @override
  void initState() {
    super.initState();
    _titleController.addListener(_suggestCategory);
    _merchantController.addListener(_suggestCategory);
    _titleController.addListener(_suggestTaxTag);
    _merchantController.addListener(_suggestTaxTag);
    _noteController.addListener(_suggestTaxTag);
  }

  void _suggestTaxTag() {
    if (_taxTouched) return;
    final suggestion = TaxTagSuggester.suggest(
      title: _titleController.text,
      merchant: _merchantController.text,
      note: _noteController.text,
    );
    if (suggestion == _taxTag && (suggestion != null) == _taxSuggested) return;
    setState(() {
      _taxTag = suggestion;
      _taxSuggested = suggestion != null;
    });
  }

  void _pickTaxTag(TaxSection? section) {
    setState(() {
      _taxTag = section;
      _taxTouched = true;
      _taxSuggested = false;
    });
  }

  void _suggestCategory() {
    if (_categoryTouched) return;

    final state = context.read<ExpenseBloc>().state;
    final history = state is ExpenseLoaded ? state.expenses : const <Never>[];
    final available = {for (final c in ExpenseCategories.all) c.id};

    final suggestion = CategorySuggester.suggest(
      merchant: _merchantController.text,
      title: _titleController.text,
      history: history,
      isAvailable: available.contains,
    );

    final id = suggestion?.categoryId;
    if (id == _selectedCategoryId && (id != null) == _categorySuggested) {
      return;
    }
    setState(() {
      _selectedCategoryId = id;
      _categorySuggested = id != null;
    });
  }

  void _pickCategory(String id) {
    setState(() {
      _selectedCategoryId = id;
      _categoryTouched = true;
      _categorySuggested = false;
    });
  }

  Future<void> _addByVoice() async {
    final locale = context.read<LocaleCubit>().state.languageCode;
    final ids = [for (final c in ExpenseCategories.all) c.id];
    final draft = await VoiceEntrySheet.show(
      context,
      create: () => sl<VoiceEntryCubit>(
        param1: VoiceEntryCubit.localeFor(locale),
        param2: ids,
      ),
    );
    if (draft != null && mounted) _applyVoiceDraft(draft);
  }

  void _applyVoiceDraft(VoiceExpenseDraft draft) {
    final currency = context.read<CurrencyCubit>();
    final amount = draft.amount;
    if (amount != null) {
      // "rupees" means INR even when the display/trip currency differs.
      final trip = _tripCurrency;
      final tripRate = trip == null ? null : currency.rateToInr(trip);
      final display = !draft.amountIsInr
          ? amount
          : tripRate != null
          ? amount / tripRate
          : currency.convertFromInr(amount);
      _amountController.text = display == display.roundToDouble()
          ? display.toStringAsFixed(0)
          : display.toStringAsFixed(2);
    }
    // Text first: the listeners re-run suggestions, then the draft's own
    // category (if any) wins.
    if (draft.title != null) _titleController.text = draft.title!;
    if (draft.merchant != null) _merchantController.text = draft.merchant!;

    setState(() {
      if (draft.categoryId != null) {
        _selectedCategoryId = draft.categoryId;
        _categorySuggested = true;
      }
      if (draft.paymentMethod != null) _paymentMethod = draft.paymentMethod;
    });

    NeuSnackBar.show(
      context: context,
      message: AppLocalizations.of(context).voice_filled(draft.transcript),
      type: NeuSnackBarType.info,
    );
  }

  /// Expense date taken from a scanned receipt; `null` means now.
  DateTime? _receiptDate;

  Future<void> _scanReceipt() async {
    final state = context.read<ExpenseBloc>().state;
    final history = state is ExpenseLoaded ? state.expenses : const <Never>[];
    final available = {for (final c in ExpenseCategories.all) c.id};
    final draft = await ReceiptScanSheet.show(
      context,
      scan: (path) => sl<ScanReceiptUseCase>()(
        path,
        history: history,
        isAvailable: available.contains,
      ),
    );
    if (draft != null && mounted) _applyReceipt(draft);
  }

  void _applyReceipt(ReceiptDraft draft) {
    final currency = context.read<CurrencyCubit>();
    final total = draft.total;
    if (total != null) {
      final trip = _tripCurrency;
      final tripRate = trip == null ? null : currency.rateToInr(trip);
      final display = tripRate != null
          ? total / tripRate
          : currency.convertFromInr(total);
      _amountController.text = display == display.roundToDouble()
          ? display.toStringAsFixed(0)
          : display.toStringAsFixed(2);
    }
    final title = draft.merchant ??
        (draft.items.isEmpty ? null : draft.items.first.name);
    if (title != null) {
      _titleController.text = title.length > NoteLimits.titleMaxLength
          ? title.substring(0, NoteLimits.titleMaxLength)
          : title;
    }
    if (draft.merchant != null) {
      final m = draft.merchant!;
      _merchantController.text = m.length > NoteLimits.merchantMaxLength
          ? m.substring(0, NoteLimits.merchantMaxLength)
          : m;
    }
    if (draft.items.isNotEmpty && _noteController.text.trim().isEmpty) {
      final summary = draft.items
          .map((i) => '${i.name} ${i.amount.toStringAsFixed(0)}')
          .join(', ');
      _noteController.text = summary.length > NoteLimits.maxLength
          ? '${summary.substring(0, NoteLimits.maxLength - 1)}…'
          : summary;
    }
    final today = DateUtils.dateOnly(DateTime.now());
    setState(() {
      if (draft.categoryId != null) {
        _selectedCategoryId = draft.categoryId;
        _categorySuggested = true;
      }
      if (draft.paymentMethod != null) _paymentMethod = draft.paymentMethod;
      _receiptDate = draft.date == null || draft.date == today
          ? null
          : draft.date;
    });
  }

  Future<void> _createCategory() async {
    final created = await CategoryEditorSheet.show(context);
    if (created != null && mounted) _pickCategory(created.id);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final isTicking = TickerMode.valuesOf(context).enabled;

    if (isTicking && !_wasTicking) {
      _resetForm();
    }

    _wasTicking = isTicking;
  }

  void _resetForm() {
    _amountController.clear();
    _titleController.clear();
    _merchantController.clear();
    _noteController.clear();

    setState(() {
      _selectedCategoryId = null;
      _paymentMethod = null;
      _repeat = null;
      _taxTag = null;
      _taxTouched = false;
      _taxSuggested = false;
      _categoryTouched = false;
      _categorySuggested = false;
      _activeEvents = _loadActiveEvents();
      _pickedEvent = null;
      _eventTouched = false;
      _receiptDate = null;
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _titleController.dispose();
    _merchantController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _saveExpense() {
    final currencyCubit = context.read<CurrencyCubit>();
    final l10n = AppLocalizations.of(context);

    final enteredAmount = double.tryParse(_amountController.text);

    if (enteredAmount == null || enteredAmount <= 0) {
      NeuSnackBar.show(
        context: context,
        message: l10n.addExpense_validAmount,
        type: NeuSnackBarType.error,
      );
      return;
    }

    if (_selectedCategoryId == null) {
      NeuSnackBar.show(
        context: context,
        message: l10n.addExpense_selectCategory,
        type: NeuSnackBarType.error,
      );
      return;
    }

    if (_titleController.text.trim().isEmpty) {
      NeuSnackBar.show(
        context: context,
        message: l10n.addExpense_titleRequired,
        type: NeuSnackBarType.error,
      );
      return;
    }

    if (_paymentMethod == null) {
      NeuSnackBar.show(
        context: context,
        message: l10n.addExpense_selectPaymentMethod,
        type: NeuSnackBarType.error,
      );
      return;
    }

    final tripCurrency = _tripCurrency;
    final currencyCode = tripCurrency ?? currencyCubit.state.selected.code;
    final tripRate = tripCurrency == null
        ? null
        : currencyCubit.rateToInr(tripCurrency);
    if (tripCurrency != null && tripRate == null) {
      // Recording 100 THB as ₹100 would be silently wrong.
      NeuSnackBar.show(
        context: context,
        message: l10n.events_noRate(tripCurrency),
        type: NeuSnackBarType.error,
      );
      return;
    }
    final amountInInr = double.parse(
      (tripRate != null
              ? enteredAmount * tripRate
              : currencyCubit.convertToInr(
                  amount: enteredAmount,
                  fromCurrency: currencyCode,
                ))
          .toStringAsFixed(2),
    );

    _isSaving = true;

    context.read<ExpenseBloc>().add(
      AddExpenseEvent(
        amount: amountInInr,
        currency: currencyCode,
        originalAmount: enteredAmount,
        exchangeRate: currencyCubit.rateToInr(currencyCode),
        categoryId: _selectedCategoryId!,
        note: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
        title: _titleController.text.trim(),
        merchant: _merchantController.text.trim().isEmpty
            ? null
            : _merchantController.text.trim(),
        paymentMethod: _paymentMethod,
        date: _receiptDate == null
            ? DateTime.now()
            : DateTime(
                _receiptDate!.year,
                _receiptDate!.month,
                _receiptDate!.day,
                12,
              ),
        repeat: _repeat,
        taxTag: _taxTag?.code,
        eventId: _event?.id,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.watch<ThemeCubit>().state.palette;

    return BlocConsumer<ExpenseBloc, ExpenseState>(
      listener: (context, state) {
        if (state is ExpenseLoaded && _isSaving) {
          _isSaving = false;

          NeuSnackBar.show(
            context: context,
            message:
                state.syncWarning ??
                AppLocalizations.of(context).addExpense_added,
            type: state.syncWarning != null
                ? NeuSnackBarType.info
                : NeuSnackBarType.success,
          );

          context.go('/dashboard');
        }

        if (state is ExpenseFailure) {
          NeuSnackBar.show(
            context: context,
            message: state.message,
            type: NeuSnackBarType.error,
          );
        }
      },

      builder: (BuildContext context, ExpenseState state) {
        final loading = state is ExpenseLoading;
        final l10n = AppLocalizations.of(context);
        return Scaffold(
          backgroundColor: palette.background,
          body: TabReveal(
            child: SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 10.h),
                    Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              l10n.addExpense_title,
                              style: AppTextStyles.manrope(
                                fontSize: 18.sp,
                                fontWeight: FontWeight.bold,
                                color: palette.textDark,
                              ),
                            ),
                            Row(
                              children: [
                                Semantics(
                                  label: l10n.receipt_button,
                                  button: true,
                                  child: NeuIconButton(
                                    icon: Icons.document_scanner_outlined,
                                    onTap: loading ? null : _scanReceipt,
                                  ),
                                ),
                                SizedBox(width: 12.w),
                                Semantics(
                                  label: l10n.voice_button,
                                  button: true,
                                  child: NeuIconButton(
                                    icon: Icons.mic_none_rounded,
                                    onTap: loading ? null : _addByVoice,
                                  ),
                                ),
                                SizedBox(width: 12.w),
                                NeuIconButton(
                                  icon: Icons.check,
                                  onTap: loading ? null : _saveExpense,
                                  loading: loading,
                                ),
                              ],
                            ),
                          ],
                        )
                        .animate()
                        .fadeIn(duration: 280.ms, curve: Curves.easeOut)
                        .slideY(
                          begin: 0.06,
                          end: 0,
                          curve: Curves.easeOutCubic,
                        ),
                    SizedBox(height: 24.h),
                    Container(
                          height: 100.h,
                          width: double.infinity,
                          decoration: ConcaveDecoration(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16.r),
                              side: BorderSide(
                                color: palette.shadowDarkLight,
                                width: .2,
                              ),
                            ),
                            depth: -8,
                            colors: [palette.shadowDark, palette.shadowLight],
                            opacity: .5,
                          ),
                          child: AmountInput(
                            controller: _amountController,
                            currencyLabel: _tripCurrency,
                          ),
                        )
                        .animate(delay: 120.ms)
                        .fadeIn(duration: 280.ms, curve: Curves.easeOut)
                        .slideY(
                          begin: 0.06,
                          end: 0,
                          curve: Curves.easeOutCubic,
                        ),
                    if (_receiptDate != null) ...[
                      SizedBox(height: 10.h),
                      InputChip(
                        avatar: const Icon(Icons.event, size: 16),
                        label: Text(
                          l10n.receipt_dateChip(
                            DateFormat.MMMd(l10n.localeName).format(_receiptDate!),
                          ),
                        ),
                        onDeleted: () => setState(() => _receiptDate = null),
                      ),
                    ],
                    SizedBox(height: 24.h),
                    Text(
                          l10n.addExpense_titleLabel,
                          style: AppTextStyles.manrope(
                            fontSize: 14.sp,
                            color: palette.textDark,
                            fontWeight: FontWeight.w600,
                          ),
                        )
                        .animate(delay: 160.ms)
                        .fadeIn(duration: 260.ms, curve: Curves.easeOut),
                    SizedBox(height: 12.h),
                    NeuTextField(
                          height: 56.h,
                          controller: _titleController,
                          hint: l10n.addExpense_expenseTitle,
                        )
                        .animate(delay: 180.ms)
                        .fadeIn(duration: 280.ms, curve: Curves.easeOut)
                        .slideY(
                          begin: 0.06,
                          end: 0,
                          curve: Curves.easeOutCubic,
                        ),
                    SizedBox(height: 24.h),
                    Text(
                          l10n.addExpense_merchantLabel,
                          style: AppTextStyles.manrope(
                            fontSize: 14.sp,
                            color: palette.textDark,
                            fontWeight: FontWeight.w600,
                          ),
                        )
                        .animate(delay: 185.ms)
                        .fadeIn(duration: 260.ms, curve: Curves.easeOut),
                    SizedBox(height: 12.h),
                    NeuTextField(
                          height: 56.h,
                          controller: _merchantController,
                          hint: l10n.addExpense_merchantHint,
                          maxLength: NoteLimits.merchantMaxLength,
                        )
                        .animate(delay: 190.ms)
                        .fadeIn(duration: 280.ms, curve: Curves.easeOut)
                        .slideY(
                          begin: 0.06,
                          end: 0,
                          curve: Curves.easeOutCubic,
                        ),
                    SizedBox(height: 24.h),
                    Row(
                          children: [
                            Text(
                              l10n.addExpense_categoryLabel,
                              style: AppTextStyles.manrope(
                                fontSize: 14.sp,
                                color: palette.textDark,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (_categorySuggested) ...[
                              SizedBox(width: 8.w),
                              Text(
                                l10n.addExpense_categorySuggested,
                                style: AppTextStyles.manrope(
                                  fontSize: 12.sp,
                                  color: palette.accent,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ],
                        )
                        .animate(delay: 200.ms)
                        .fadeIn(duration: 260.ms, curve: Curves.easeOut),
                    SizedBox(height: 12.h),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      // Last cell is the "+ new category" tile.
                      itemCount: ExpenseCategories.all.length + 1,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        crossAxisSpacing: 12.w,
                        childAspectRatio: 0.8,
                      ),
                      itemBuilder: (context, index) {
                        final categories = ExpenseCategories.all;
                        if (index == categories.length) {
                          return Center(
                            child: SizedBox(
                              width: 70.w,
                              height: 70.h,
                              child: CategoryTile(
                                emoji: '➕',
                                isSelected: false,
                                onTap: _createCategory,
                              ),
                            ),
                          );
                        }
                        final category = categories[index];

                        return Center(
                          child: SizedBox(
                            width: 70.w,
                            height: 70.h,
                            child:
                                CategoryTile(
                                      emoji: category.emoji,
                                      isSelected:
                                          _selectedCategoryId == category.id,
                                      onTap: () => _pickCategory(category.id),
                                    )
                                    .animate(delay: (220 + index * 40).ms)
                                    .fadeIn(
                                      duration: 300.ms,
                                      curve: Curves.easeOut,
                                    )
                                    .slideY(
                                      begin: 0.12,
                                      end: 0,
                                      curve: Curves.easeOutCubic,
                                    ),
                          ),
                        );
                      },
                    ),
                    SizedBox(height: 24.h),
                    Text(
                          l10n.addExpense_paymentMethodLabel,
                          style: AppTextStyles.manrope(
                            fontSize: 14.sp,
                            color: palette.textDark,
                            fontWeight: FontWeight.w600,
                          ),
                        )
                        .animate(delay: 360.ms)
                        .fadeIn(duration: 260.ms, curve: Curves.easeOut),
                    SizedBox(height: 12.h),
                    Wrap(
                      spacing: 10.w,
                      runSpacing: 10.h,
                      children: [
                        for (final method in PaymentMethods.all)
                          _paymentChip(palette, method)
                              .animate(
                                delay:
                                    (400 +
                                            PaymentMethods.all.indexOf(method) *
                                                35)
                                        .ms,
                              )
                              .fadeIn(duration: 280.ms, curve: Curves.easeOut)
                              .slideY(
                                begin: 0.06,
                                end: 0,
                                curve: Curves.easeOutCubic,
                              ),
                      ],
                    ),
                    SizedBox(height: 24.h),
                    Text(
                          l10n.addExpense_repeatLabel,
                          style: AppTextStyles.manrope(
                            fontSize: 14.sp,
                            color: palette.textDark,
                            fontWeight: FontWeight.w600,
                          ),
                        )
                        .animate(delay: 480.ms)
                        .fadeIn(duration: 260.ms, curve: Curves.easeOut),
                    SizedBox(height: 12.h),
                    Wrap(
                      spacing: 10.w,
                      runSpacing: 10.h,
                      children: [
                        _choiceChip(
                          palette,
                          label: l10n.recurrence_none,
                          selected: _repeat == null,
                          onTap: () => setState(() => _repeat = null),
                        ),
                        for (final frequency in RecurrenceFrequency.values)
                          _choiceChip(
                            palette,
                            label: frequency.label(l10n),
                            selected: _repeat == frequency,
                            onTap: () => setState(() => _repeat = frequency),
                          ),
                      ],
                    ).animate(delay: 500.ms).fadeIn(duration: 280.ms),
                    SizedBox(height: 24.h),
                    TaxTagPicker(
                      selected: _taxTag,
                      suggested: _taxSuggested,
                      enabled: !_isSaving,
                      onChanged: _pickTaxTag,
                    ).animate(delay: 510.ms).fadeIn(duration: 280.ms),
                    if (_activeEvents.isNotEmpty) ...[
                      SizedBox(height: 24.h),
                      EventTagPicker(
                        events: _activeEvents,
                        selected: _event,
                        suggested: !_eventTouched,
                        enabled: !_isSaving,
                        onChanged: (e) => setState(() {
                          _pickedEvent = e;
                          _eventTouched = true;
                        }),
                      ).animate(delay: 515.ms).fadeIn(duration: 280.ms),
                    ],
                    SizedBox(height: 24.h),
                    Text(
                          l10n.addExpense_note,
                          style: AppTextStyles.manrope(
                            fontSize: 14.sp,
                            color: palette.textDark,
                            fontWeight: FontWeight.w600,
                          ),
                        )
                        .animate(delay: 520.ms)
                        .fadeIn(duration: 260.ms, curve: Curves.easeOut),
                    SizedBox(height: 12.h),
                    Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            NeuTextField(
                              height: 90.h,
                              controller: _noteController,
                              hint: l10n.addExpense_noteHint,
                              maxLength: NoteLimits.maxLength,
                            ),
                            SizedBox(height: 6.h),
                            Align(
                              alignment: Alignment.centerRight,
                              child: ValueListenableBuilder<TextEditingValue>(
                                valueListenable: _noteController,
                                builder: (context, value, _) {
                                  return Text(
                                    "${value.text.length}/${NoteLimits.maxLength} *",
                                    style: AppTextStyles.manrope(
                                      fontSize: 11.sp,
                                      color: palette.textDark.withValues(
                                        alpha: .5,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        )
                        .animate(delay: 560.ms)
                        .fadeIn(duration: 280.ms, curve: Curves.easeOut)
                        .slideY(
                          begin: 0.06,
                          end: 0,
                          curve: Curves.easeOutCubic,
                        ),
                    SizedBox(height: 24.h),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _choiceChip(
    NeuPalette palette, {
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: _isSaving ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 14.w),
        decoration: NeuBox.raised(
          palette,
          radius: 14.r,
          bgColor: selected ? palette.accent : palette.background,
        ),
        child: Text(
          label,
          style: AppTextStyles.manrope(
            fontSize: 13.sp,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            color: selected ? palette.background : palette.textDark,
          ),
        ),
      ),
    );
  }

  Widget _paymentChip(NeuPalette palette, String method) {
    final isSelected = _paymentMethod == method;
    final l10n = AppLocalizations.of(context);

    return GestureDetector(
      onTap: _isSaving ? null : () => setState(() => _paymentMethod = method),
      child: AnimatedScale(
        scale: isSelected ? 1.06 : 1.0,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutBack,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 14.w),
          decoration: NeuBox.raised(
            palette,
            radius: 14.r,
            bgColor: isSelected ? palette.accent : palette.background,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                PaymentMethods.emojis[method] ?? '💸',
                style: TextStyle(fontSize: 18.sp),
              ),
              SizedBox(width: 6.w),
              Text(
                PaymentMethods.localizedLabel(l10n, method),
                style: AppTextStyles.manrope(
                  fontSize: 13.sp,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? palette.background : palette.textDark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
