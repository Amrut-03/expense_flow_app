import 'package:expense_flow_app/core/theme/app_text_styles.dart';
import 'package:animated_digit/animated_digit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/expense_category.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../currency/presentation/util/currency_formatter.dart';
import '../../domain/services/budget_progress_calculator.dart';
import '../bloc/budget_insights_cubit.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/neumorphic_styles.dart';
import '../../../../core/theme/theme_cubit.dart';
import '../../../../core/widgets/neu_app_bar.dart';
import '../../../../core/widgets/neu_button.dart';
import '../../../../core/widgets/neu_loading.dart';
import '../../../../core/widgets/tab_reveal.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../categories/presentation/widgets/category_stat_tile.dart';
import '../../../currency/presentation/cubit/currency_cubit.dart';
import '../../../expense/presentation/bloc/expense_bloc.dart';
import '../../../expense/presentation/bloc/expense_event.dart';
import '../../../expense/presentation/bloc/expense_state.dart';
import '../bloc/budget_limits_bloc.dart';
import '../bloc/budget_limits_event.dart';
import '../bloc/budget_limits_state.dart';
import '../widgets/budget_segmented_bar.dart';
import 'empty_budget_screen.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => BudgetScreenState();
}

class BudgetScreenState extends State<BudgetScreen> {
  double _displayedTotal = 0;
  bool _wasTickingLastCheck = false;

  void _playRevealAnimation(double total) {
    setState(() => _displayedTotal = 0);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _displayedTotal = total);
    });
  }

  @override
  void initState() {
    super.initState();
    context.read<ExpenseBloc>().add(const LoadExpensesEvent());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final isTicking = TickerMode.valuesOf(context).enabled;
    if (isTicking && !_wasTickingLastCheck) {
      if (context.read<ExpenseBloc>().state is ExpenseLoaded) {
        _playRevealAnimation(
          context.read<BudgetInsightsCubit>().state.spentThisMonth,
        );
      }
    }
    _wasTickingLastCheck = isTicking;
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.watch<ThemeCubit>().state.palette;
    final currencyCubit = context.watch<CurrencyCubit>();
    final l10n = AppLocalizations.of(context);

    return BlocBuilder<BudgetLimitsBloc, BudgetLimitsState>(
      builder: (context, budgetState) {
        if (budgetState is BudgetLimitsLoading) {
          return Scaffold(
            backgroundColor: palette.background,
            body: SafeArea(child: const NeuLoading()),
          );
        }

        if (budgetState is BudgetLimitsError) {
          return Scaffold(
            backgroundColor: palette.background,
            body: SafeArea(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 32.w),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.cloud_off_rounded,
                        size: 48.h,
                        color: palette.textMuted,
                      ),
                      SizedBox(height: 16.h),
                      Text(
                        budgetState.message,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.manrope(
                          fontSize: 14.sp,
                          color: palette.textDark.withValues(alpha: .7),
                        ),
                      ),
                      SizedBox(height: 20.h),
                      SizedBox(
                        width: double.infinity,
                        child: NeuButton(
                          label: l10n.common_retry,
                          onTap: () => context.read<BudgetLimitsBloc>().add(
                            const LoadBudgetLimits(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        if (budgetState is! BudgetLimitsLoaded) {
          return BudgetEmptyStateScreen(
            onPop: () => StatefulNavigationShell.of(context).goBranch(0),
          );
        }

        final budgetLoaded = budgetState;
        if (!budgetLoaded.hasAnyBudget) {
          return BudgetEmptyStateScreen(
            onPop: () => StatefulNavigationShell.of(context).goBranch(0),
          );
        }

        return BlocBuilder<ExpenseBloc, ExpenseState>(
          builder: (context, state) {
            final insights = context.watch<BudgetInsightsCubit>().state;

            // Headline and breakdown cover this calendar month. A budgeted
            // category is measured over its own period (month, quarter or
            // year) so its bar matches its limit.
            final totalSpent = insights.spentThisMonth;
            final categorySpent = <String, double>{
              ...insights.spentThisMonthByCategory,
              for (final b in insights.budgets) b.categoryId: b.spent,
            };

            final activeCategories =
                {
                      for (final cat in ExpenseCategories.all) cat.id: cat,
                      for (final b in insights.budgets)
                        b.categoryId: ExpenseCategories.byId(b.categoryId),
                    }.values
                    .where(
                      (cat) =>
                          (categorySpent[cat.id] ?? 0) > 0 ||
                          insights.budgetFor(cat.id) != null,
                    )
                    .toList();

            if (_displayedTotal == 0 && totalSpent > 0) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) setState(() => _displayedTotal = totalSpent);
              });
            }

            return Scaffold(
              backgroundColor: palette.background,
              body: TabReveal(
                child: SafeArea(
                  child: Column(
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24.w),
                        child: NeuAppBar(
                          title: l10n.budget_title,
                          onBack: () =>
                              StatefulNavigationShell.of(context).goBranch(0),
                          trailing: GestureDetector(
                            onTap: () => context.push('/budget/edit'),
                            child: Container(
                              width: 44.w,
                              height: 44.h,
                              alignment: Alignment.center,
                              decoration: NeuBox.raised(palette, radius: 16.r),
                              child: Center(
                                child: Icon(
                                  Icons.edit_outlined,
                                  size: 18.h,
                                  color: palette.textDark,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: EdgeInsets.symmetric(horizontal: 24.w),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: 16.h),
                              Container(
                                    width: double.infinity,
                                    decoration: NeuBox.raised(
                                      palette,
                                      radius: 16.r,
                                    ),
                                    padding: EdgeInsets.all(20.h),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          l10n.budget_totalSpentThisMonth,
                                          style: AppTextStyles.manrope(
                                            fontSize: 12.sp,
                                            color: palette.textDark.withValues(
                                              alpha: .5,
                                            ),
                                          ),
                                        ),
                                        SizedBox(height: 10.h),
                                        AnimatedDigitWidget(
                                          value: currencyCubit.convertFromInr(
                                            _displayedTotal,
                                          ),
                                          textStyle: AppTextStyles.manrope(
                                            fontSize: 30.sp,
                                            fontWeight: FontWeight.bold,
                                            color: palette.textDark,
                                          ),
                                          prefix: currencyCubit
                                              .state
                                              .selected
                                              .symbol,
                                          fractionDigits: 2,
                                          enableSeparator: true,
                                          duration: const Duration(
                                            milliseconds: 700,
                                          ),
                                          curve: Curves.easeOutCubic,
                                        ),
                                      ],
                                    ),
                                  )
                                  .animate()
                                  .fadeIn(
                                    duration: 320.ms,
                                    curve: Curves.easeOut,
                                  )
                                  .slideY(
                                    begin: 0.06,
                                    end: 0,
                                    curve: Curves.easeOutCubic,
                                  ),
                              if (activeCategories.isNotEmpty) ...[
                                SizedBox(height: 16.h),
                                BudgetSegmentedBar(
                                      categories: activeCategories,
                                      categorySpent: categorySpent,
                                      totalSpent: totalSpent,
                                      palette: palette,
                                      currencySymbol:
                                          currencyCubit.state.selected.symbol,
                                      convert: currencyCubit.convertFromInr,
                                    )
                                    .animate(delay: 120.ms)
                                    .fadeIn(
                                      duration: 280.ms,
                                      curve: Curves.easeOut,
                                    )
                                    .slideY(
                                      begin: 0.06,
                                      end: 0,
                                      curve: Curves.easeOutCubic,
                                    ),
                              ],
                              SizedBox(height: 16.h),
                              Column(
                                children: [
                                  for (
                                    int i = 0;
                                    i < activeCategories.length;
                                    i++
                                  ) ...[
                                    CategoryStatTile(
                                          subtitle: _paceLabel(
                                            context,
                                            insights.budgetFor(
                                              activeCategories[i].id,
                                            ),
                                          ),
                                          subtitleColor: _paceColor(
                                            palette,
                                            insights.budgetFor(
                                              activeCategories[i].id,
                                            ),
                                          ),
                                          emoji: activeCategories[i].emoji,
                                          label: activeCategories[i].labelOf(
                                            l10n,
                                          ),
                                          spent: currencyCubit.convertFromInr(
                                            categorySpent[activeCategories[i]
                                                    .id] ??
                                                0,
                                          ),
                                          budget: currencyCubit.convertFromInr(
                                            insights
                                                    .budgetFor(
                                                      activeCategories[i].id,
                                                    )
                                                    ?.limit ??
                                                budgetLoaded
                                                    .limits[activeCategories[i]
                                                    .id] ??
                                                totalSpent,
                                          ),
                                          progressColor:
                                              ExpenseCategories.colorFor(
                                                palette,
                                                activeCategories[i].id,
                                              ),
                                          currencySymbol: currencyCubit
                                              .state
                                              .selected
                                              .symbol,
                                          onTap: () => context.push(
                                            '/category-transactions',
                                            extra: {
                                              'categoryId':
                                                  activeCategories[i].id,
                                              'label': activeCategories[i]
                                                  .labelOf(l10n),
                                              'emoji':
                                                  activeCategories[i].emoji,
                                            },
                                          ),
                                        )
                                        .animate(delay: (i * 50).ms)
                                        .fadeIn(
                                          duration: 260.ms,
                                          curve: Curves.easeOut,
                                        )
                                        .slideY(
                                          begin: 0.08,
                                          end: 0,
                                          curve: Curves.easeOutCubic,
                                        ),
                                    if (i != activeCategories.length - 1)
                                      SizedBox(height: 12.h),
                                  ],
                                  if (state is ExpenseLoading)
                                    Padding(
                                      padding: EdgeInsets.symmetric(
                                        vertical: 24.h,
                                      ),
                                      child: const NeuLoading(),
                                    ),
                                  if (activeCategories.isEmpty &&
                                      state is ExpenseLoaded)
                                    Padding(
                                      padding: EdgeInsets.symmetric(
                                        vertical: 24.h,
                                      ),
                                      child: Center(
                                        child: Text(
                                          l10n.budget_noExpensesYet,
                                          style: AppTextStyles.manrope(
                                            fontSize: 14.sp,
                                            color: palette.textDark.withValues(
                                              alpha: .5,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              SizedBox(height: 24.h),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  String? _paceLabel(BuildContext context, CategoryBudgetProgress? budget) {
    if (budget == null) return null;
    final l10n = AppLocalizations.of(context);
    final currency = context.read<CurrencyCubit>();
    String money(double inr) =>
        CurrencyFormatter.format(cubit: currency, amountInInr: inr);

    final pace = switch (budget.status) {
      BudgetPaceStatus.exceeded => l10n.budget_paceExceeded(
        money(budget.spent - budget.limit),
      ),
      BudgetPaceStatus.atRisk => l10n.budget_paceAtRisk(
        DateFormat.MMMd(l10n.localeName).format(budget.projectedRunOutDate!),
      ),
      BudgetPaceStatus.onTrack => l10n.budget_paceOnTrack(
        money(budget.dailyAllowance),
        budget.daysLeft,
      ),
    };
    if (budget.carriedOver <= 0) return pace;
    return '$pace\n${l10n.rollover_includes(money(budget.carriedOver))}';
  }

  Color? _paceColor(NeuPalette palette, CategoryBudgetProgress? budget) {
    return switch (budget?.status) {
      BudgetPaceStatus.exceeded => palette.danger,
      BudgetPaceStatus.atRisk => palette.accent,
      BudgetPaceStatus.onTrack => palette.success,
      null => null,
    };
  }
}
