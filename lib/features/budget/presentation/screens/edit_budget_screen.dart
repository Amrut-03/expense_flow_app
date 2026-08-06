import 'package:expense_flow_app/core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/expense_category.dart';
import '../../../../core/theme/neumorphic_styles.dart';
import '../../../../core/theme/theme_cubit.dart';
import '../../../../core/widgets/neu_app_bar.dart';
import '../../../../core/widgets/neu_button.dart';
import '../../../../core/widgets/neu_chip.dart';
import '../../../../core/widgets/neu_icon_button.dart';
import '../../../../core/widgets/neu_snack_bar.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../currency/presentation/cubit/currency_cubit.dart';
import '../../../expense/domain/entities/expense_entity.dart';
import '../../../expense/presentation/bloc/expense_bloc.dart';
import '../../../expense/presentation/bloc/expense_state.dart';
import '../../domain/entities/budget_entity.dart';
import '../../domain/usecases/get_suggested_slider_max_usecase.dart';
import '../bloc/budget_limits_bloc.dart';
import '../bloc/budget_limits_event.dart';
import '../bloc/budget_limits_state.dart';

/// Lets the user set (or edit) a monthly budget limit per category.
/// Each card has a numeric field and a slider kept in sync, plus a
/// warning badge when current spend is already close to or past the
/// limit being edited.
class BudgetEditScreen extends StatefulWidget {
  const BudgetEditScreen({super.key});

  @override
  State<BudgetEditScreen> createState() => _BudgetEditScreenState();
}

class _BudgetEditScreenState extends State<BudgetEditScreen> {
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, FocusNode> _focusNodes = {};
  final Map<String, double> _draftLimits = {};
  final Map<String, BudgetPeriod> _draftPeriods = {};
  Map<String, double> _originalLimits = {};
  Map<String, BudgetPeriod> _originalPeriods = {};
  bool _loading = false;

  bool get _hasChanges =>
      _draftLimits.entries.any(
        (e) => e.value != (_originalLimits[e.key] ?? 0),
      ) ||
      _draftPeriods.entries.any(
        (e) => e.value != (_originalPeriods[e.key] ?? BudgetPeriod.monthly),
      );

  @override
  void initState() {
    super.initState();
    final state = context.read<BudgetLimitsBloc>().state;
    final limits = state is BudgetLimitsLoaded
        ? state.limits
        : <String, double>{};
    final periods = state is BudgetLimitsLoaded
        ? state.periods
        : <String, BudgetPeriod>{};
    _originalLimits = Map.from(limits);
    _originalPeriods = Map.from(periods);
    for (final category in ExpenseCategories.all) {
      final current = limits[category.id] ?? 0;
      _draftLimits[category.id] = current;
      _draftPeriods[category.id] = periods[category.id] ?? BudgetPeriod.monthly;
      _controllers[category.id] = TextEditingController(
        text: current > 0 ? current.toStringAsFixed(0) : '',
      );
      _focusNodes[category.id] = FocusNode();
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    for (final f in _focusNodes.values) {
      f.dispose();
    }
    super.dispose();
  }

  void _updateLimit(String categoryId, double value) {
    setState(() {
      _draftLimits[categoryId] = value;
      final text = value > 0 ? value.toStringAsFixed(0) : '';
      if (_controllers[categoryId]!.text != text) {
        _controllers[categoryId]!.text = text;
      }
    });
    _focusNodes[categoryId]?.requestFocus();
  }

  void _updatePeriod(String categoryId, BudgetPeriod period) {
    setState(() => _draftPeriods[categoryId] = period);
  }

  Future<void> _save() async {
    setState(() => _loading = true);
    final bloc = context.read<BudgetLimitsBloc>();
    final done = bloc.stream.firstWhere(
      (s) => s is BudgetLimitsLoaded || s is BudgetLimitsError,
    );
    bloc.add(SetBudgetLimits(_draftLimits, periods: _draftPeriods));
    final state = await done;
    if (!mounted) return;
    setState(() => _loading = false);
    if (state is BudgetLimitsError) {
      NeuSnackBar.show(
        context: context,
        message: state.message,
        type: NeuSnackBarType.error,
      );
      return;
    }
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.watch<ThemeCubit>().state.palette;
    final currencyCubit = context.watch<CurrencyCubit>();
    final expenseState = context.watch<ExpenseBloc>().state;
    final l10n = AppLocalizations.of(context);

    final categorySpent = <String, double>{};
    if (expenseState is ExpenseLoaded) {
      for (final expense in expenseState.expenses) {
        categorySpent.update(
          expense.categoryId,
          (v) => v + expense.amount,
          ifAbsent: () => expense.amount,
        );
      }
    }

    final totalBudget = _draftLimits.values.fold<double>(0, (s, v) => s + v);
    final symbol = currencyCubit.state.selected.symbol;

    final expenses = expenseState is ExpenseLoaded
        ? expenseState.expenses
        : <ExpenseEntity>[];
    final suggestedMax = GetSuggestedSliderMaxUseCase().call(expenses);

    final isEditMode = _originalLimits.values.any((v) => v > 0);
    final visibleCategories = isEditMode
        ? ExpenseCategories.all
              .where(
                (c) =>
                    (categorySpent[c.id] ?? 0) > 0 ||
                    (_draftLimits[c.id] ?? 0) > 0,
              )
              .toList()
        : ExpenseCategories.all;

    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            children: [
              NeuAppBar(
                title: _originalLimits.values.any((v) => v > 0)
                    ? l10n.budget_editBudgets
                    : l10n.budget_createBudget,
                onBack: () => context.pop(),
                trailing: _originalLimits.values.any((v) => v > 0)
                    ? NeuIconButton(
                        icon: Icons.check,
                        onTap: _hasChanges && !_loading ? _save : null,
                        loading: _loading,
                      )
                    : SizedBox(),
              ),
              if (_originalLimits.values.every((v) => v == 0)) ...[
                SizedBox(height: 8.h),
                Text(
                  l10n.budget_createHint,
                  style: AppTextStyles.manrope(
                    fontSize: 13.sp,
                    color: palette.textDark.withValues(alpha: .6),
                    height: 1.5,
                  ),
                ),
              ],
              SizedBox(height: 16.h),
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                decoration: NeuBox.raised(
                  palette,
                  radius: 16.r,
                  bgColor: palette.background,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.budget_totalMonthlyBudget,
                      style: AppTextStyles.manrope(
                        fontSize: 13.sp,
                        color: palette.textDark.withValues(alpha: .6),
                      ),
                    ),
                    Text(
                      '$symbol${currencyCubit.convertFromInr(totalBudget).toStringAsFixed(0)}',
                      style: AppTextStyles.manrope(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w600,
                        color: palette.textDark,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 12.h),
              Expanded(
                child: ListView.separated(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.manual,
                  itemCount: visibleCategories.length,
                  separatorBuilder: (_, _) => SizedBox(height: 10.h),
                  itemBuilder: (context, i) {
                    final category = visibleCategories[i];
                    final limit = _draftLimits[category.id] ?? 0;
                    final spent = categorySpent[category.id] ?? 0;
                    final percentUsed = limit > 0 ? (spent / limit * 100) : 0.0;
                    final isNearOrOver = limit > 0 && percentUsed >= 80;
                    final sliderMax =
                        (suggestedMax[category.id] ??
                                GetSuggestedSliderMaxUseCase.defaultMax)
                            .clamp(limit, double.infinity);

                    return _CategoryBudgetCard(
                          palette: palette,
                          category: category,
                          currencySymbol: symbol,
                          period:
                              _draftPeriods[category.id] ??
                              BudgetPeriod.monthly,
                          controller: _controllers[category.id]!,
                          focusNode: _focusNodes[category.id],
                          sliderValue: limit.clamp(0, sliderMax),
                          sliderMax: sliderMax,
                          percentUsed: limit > 0 ? percentUsed : null,
                          isWarning: isNearOrOver,
                          onFieldChanged: (text) {
                            final parsed = double.tryParse(text) ?? 0;
                            _updateLimit(category.id, parsed);
                          },
                          onSliderChanged: (value) =>
                              _updateLimit(category.id, value),
                          onPeriodChanged: (p) => _updatePeriod(category.id, p),
                        )
                        .animate(delay: (i * 50).ms)
                        .fadeIn(duration: 260.ms, curve: Curves.easeOut)
                        .slideY(
                          begin: 0.08,
                          end: 0,
                          curve: Curves.easeOutCubic,
                        );
                  },
                ),
              ),
              if (_originalLimits.values.every((v) => v == 0)) ...[
                SizedBox(height: 12.h),
                SizedBox(
                  width: double.infinity,
                  child: NeuButton(
                    label: l10n.budget_createBudget,
                    onTap: _hasChanges && !_loading ? _save : null,
                  ),
                ),
              ],
              SizedBox(height: 12.h),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryBudgetCard extends StatelessWidget {
  const _CategoryBudgetCard({
    required this.palette,
    required this.category,
    required this.currencySymbol,
    required this.period,
    required this.controller,
    required this.focusNode,
    required this.sliderValue,
    required this.sliderMax,
    required this.percentUsed,
    required this.isWarning,
    required this.onFieldChanged,
    required this.onSliderChanged,
    required this.onPeriodChanged,
  });

  final dynamic palette;
  final ExpenseCategory category;
  final String currencySymbol;
  final BudgetPeriod period;
  final TextEditingController controller;
  final FocusNode? focusNode;
  final double sliderValue;
  final double sliderMax;
  final double? percentUsed;
  final bool isWarning;
  final ValueChanged<String> onFieldChanged;
  final ValueChanged<double> onSliderChanged;
  final ValueChanged<BudgetPeriod> onPeriodChanged;

  String _periodLabel(AppLocalizations l10n, BudgetPeriod p) {
    switch (p) {
      case BudgetPeriod.monthly:
        return l10n.budget_periodMonthly;
      case BudgetPeriod.quarterly:
        return l10n.budget_periodQuarterly;
      case BudgetPeriod.yearly:
        return l10n.budget_periodYearly;
      case BudgetPeriod.noLimit:
        return l10n.budget_periodNoLimit;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14.h),
      decoration: NeuBox.raised(palette, radius: 14.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(category.emoji, style: TextStyle(fontSize: 16.sp)),
              SizedBox(width: 8.w),
              Text(
                category.labelOf(l10n),
                style: AppTextStyles.manrope(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: palette.textDark,
                ),
              ),
              const Spacer(),
              PopupMenuButton<BudgetPeriod>(
                onSelected: onPeriodChanged,
                initialValue: period,
                padding: EdgeInsets.zero,
                constraints: BoxConstraints(minWidth: 100.w),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.r),
                ),
                itemBuilder: (_) => BudgetPeriod.values.map((p) {
                  return PopupMenuItem(
                    value: p,
                    child: Text(
                      _periodLabel(l10n, p),
                      style: AppTextStyles.manrope(fontSize: 13.sp),
                    ),
                  );
                }).toList(),
                child: NeuChip(label: _periodLabel(l10n, period)),
              ),
              if (percentUsed != null) SizedBox(width: 8.w),
              if (percentUsed != null)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                  decoration: BoxDecoration(
                    color: isWarning
                        ? palette.danger.withValues(alpha: .12)
                        : palette.success.withValues(alpha: .12),
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                  child: Text(
                    l10n.budget_percentUsed(percentUsed!.toStringAsFixed(0)),
                    style: AppTextStyles.manrope(
                      fontSize: 11.sp,
                      color: isWarning ? palette.danger : palette.success,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 10.h),
          Row(
            children: [
              Text(
                currencySymbol,
                style: AppTextStyles.manrope(
                  fontSize: 15.sp,
                  color: palette.textDark.withValues(alpha: .6),
                ),
              ),
              SizedBox(width: 4.w),
              Expanded(
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  keyboardType: TextInputType.number,
                  onChanged: onFieldChanged,
                  style: AppTextStyles.manrope(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w600,
                    color: palette.textDark,
                  ),
                  decoration: const InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    hintText: '0',
                  ),
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
              overlayShape: SliderComponentShape.noOverlay,
            ),
            child: Slider(
              min: 0,
              max: sliderMax,
              value: sliderValue,
              activeColor: isWarning ? palette.danger : palette.accent,
              inactiveColor: palette.shadowDark.withValues(alpha: .08),
              onChanged: onSliderChanged,
            ),
          ),
        ],
      ),
    );
  }
}
