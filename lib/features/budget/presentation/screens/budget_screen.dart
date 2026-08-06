import 'package:expense_flow_app/core/theme/app_text_styles.dart';
import 'package:animated_digit/animated_digit.dart';
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
      final state = context.read<ExpenseBloc>().state;
      if (state is ExpenseLoaded) {
        final total = state.expenses.fold<double>(0, (s, e) => s + e.amount);
        _playRevealAnimation(total);
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
            double totalSpent = 0;
            final categorySpent = <String, double>{};

            if (state is ExpenseLoaded) {
              for (final expense in state.expenses) {
                totalSpent += expense.amount;
                categorySpent.update(
                  expense.categoryId,
                  (v) => v + expense.amount,
                  ifAbsent: () => expense.amount,
                );
              }
            }

            final activeCategories = ExpenseCategories.all
                .where((cat) => (categorySpent[cat.id] ?? 0) > 0)
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
                                          emoji: activeCategories[i].emoji,
                                          label: activeCategories[i].labelOf(
                                            l10n,
                                          ),
                                          spent: currencyCubit.convertFromInr(
                                            categorySpent[activeCategories[i]
                                                .id]!,
                                          ),
                                          budget: currencyCubit.convertFromInr(
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
}
