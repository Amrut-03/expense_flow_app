import 'package:expense_flow_app/core/theme/app_text_styles.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:animated_digit/animated_digit.dart';
import '../../../../core/constants/expense_category.dart';
import '../../../../core/theme/neumorphic_styles.dart';
import '../../../../core/theme/theme_cubit.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/user_display_name.dart';
import '../../../../core/widgets/concave_decoration.dart';
import '../../../../core/widgets/error_state_widget.dart';
import '../../../../core/widgets/neu_loading.dart';
import '../../../../core/widgets/sync_warning_banner.dart';
import '../../../../core/widgets/tab_reveal.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../currency/presentation/cubit/currency_cubit.dart';
import '../../../currency/presentation/util/currency_formatter.dart';
import '../../../expense/presentation/bloc/expense_bloc.dart';
import '../../../expense/presentation/bloc/expense_event.dart';
import '../../../expense/presentation/bloc/expense_state.dart';
import '../../../notifications/presentation/bloc/notifications_cubit.dart';
import '../../../notifications/presentation/bloc/notifications_state.dart';
import '../widgets/categories_tile.dart';
import '../widgets/transaction_history.dart';
import '../../domain/usecases/compute_dashboard_summary_usecase.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String formatExpenseDate(DateTime date) {
    return DateFormat('dd MMM, hh:mm a').format(date);
  }

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

  String _greeting(AppLocalizations l10n) {
    final hour = DateTime.now().hour;

    if (hour >= 5 && hour < 12) {
      return l10n.dashboard_goodMorning;
    }

    if (hour >= 12 && hour < 17) {
      return l10n.dashboard_goodAfternoon;
    }

    if (hour >= 17 && hour < 21) {
      return l10n.dashboard_goodEvening;
    }

    return l10n.dashboard_goodNight;
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
    final l10n = AppLocalizations.of(context);
    final currencyCubit = context.watch<CurrencyCubit>();
    final authState = context.select((AuthBloc bloc) => bloc.state);
    final displayName = authState is Authenticated
        ? authState.user.displayNameOrFallback
        : 'Guest';

    return BlocBuilder<ExpenseBloc, ExpenseState>(
      builder: (context, state) {
        final notificationsState = context.watch<NotificationsCubit>().state;
        if (state is ExpenseLoading) {
          return const NeuLoading();
        }

        if (state is ExpenseFailure) {
          return ErrorStateWidget(
            message: state.message,
            onRetry: () =>
                context.read<ExpenseBloc>().add(const LoadExpensesEvent()),
          );
        }

        if (state is! ExpenseLoaded) {
          return const SizedBox.shrink();
        }
        final expenses = state.expenses;

        final summary = const ComputeDashboardSummaryUseCase()(expenses);
        final totalSpent = summary.totalSpent;
        final sortedCategories = summary.sortedCategories;
        final vsLastMonthLabel = summary.vsLastMonthLabel;

        if (_displayedTotal == 0 && totalSpent > 0) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _displayedTotal = totalSpent);
          });
        }

        return TabReveal(
          child: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.w),
                  child: Column(
                    children: [
                      SizedBox(height: 10.h),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _greeting(l10n),
                                style: AppTextStyles.manrope(
                                  fontSize: 14.sp,
                                  color: palette.textDark.withValues(alpha: .5),
                                ),
                              ),
                              Text(
                                displayName,
                                style: AppTextStyles.manrope(
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.bold,
                                  color: palette.textDark,
                                ),
                              ),
                            ],
                          ),
                          GestureDetector(
                            onTap: () => context.push('/notifications'),
                            child: Container(
                              width: 44.w,
                              height: 44.h,
                              alignment: Alignment.center,
                              decoration: NeuBox.raised(palette, radius: 16.r),
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  Icon(
                                    Icons.notifications_rounded,
                                    color: palette.textDark,
                                    size: 22.sp,
                                  ),
                                  if (notificationsState
                                          is NotificationsLoaded &&
                                      notificationsState.hasUnread)
                                    Positioned(
                                      top: -3,
                                      right: -3,
                                      child: Container(
                                        width: 12.w,
                                        height: 12.w,
                                        decoration: BoxDecoration(
                                          color: palette.accent,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: palette.background,
                                            width: 2,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 10.h),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: 24.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 16.h),
                        if (state.syncWarning != null) ...[
                          SyncWarningBanner(message: state.syncWarning!),
                          SizedBox(height: 16.h),
                        ],
                        Container(
                              width: double.infinity,
                              decoration: NeuBox.raised(palette, radius: 16.r),
                              padding: EdgeInsets.all(20.h),

                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l10n.dashboard_totalSpentThisMonth,
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
                                    prefix: currencyCubit.state.selected.symbol,
                                    fractionDigits: 2,
                                    enableSeparator: true,
                                  ),
                                  SizedBox(height: 15.h),
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 8.w,
                                      vertical: 3.h,
                                    ),
                                    decoration: ConcaveDecoration(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                          16.r,
                                        ),
                                      ),
                                      depth: -8,
                                      colors: [
                                        palette.shadowDark,
                                        palette.shadowLight,
                                      ],
                                      opacity: .5,
                                    ),
                                    child: Text(
                                      vsLastMonthLabel,
                                      style: AppTextStyles.manrope(
                                        fontSize: 12.sp,
                                        color: palette.textDark,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                            .animate()
                            .fadeIn(duration: 320.ms, curve: Curves.easeOut)
                            .slideY(
                              begin: 0.06,
                              end: 0,
                              curve: Curves.easeOutCubic,
                            ),
                        SizedBox(height: 24.h),
                        Text(
                          l10n.dashboard_categories,
                          style: AppTextStyles.manrope(
                            fontSize: 14.sp,
                            color: palette.textDark,
                            fontWeight: FontWeight.w600,
                          ),
                        ).animate().fadeIn(
                          duration: 240.ms,
                          curve: Curves.easeOut,
                        ),
                        SizedBox(height: 12.h),
                        SizedBox(
                          height: 100.h,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            clipBehavior: Clip.none,
                            padding: EdgeInsets.symmetric(vertical: 10.h),
                            itemCount: sortedCategories.length,
                            separatorBuilder: (context, index) =>
                                SizedBox(width: 12.w),
                            itemBuilder: (context, index) {
                              final category = sortedCategories[index];
                              return CategoriesTile(
                                    emoji: category.emoji,
                                    label: category.labelOf(l10n),
                                    onTap: () {
                                      context.push(
                                        '/category-transactions',
                                        extra: {
                                          'categoryId': category.id,
                                          'label': category.labelOf(l10n),
                                          'emoji': category.emoji,
                                        },
                                      );
                                    },
                                  )
                                  .animate(delay: (80 + index * 40).ms)
                                  .fadeIn(
                                    duration: 260.ms,
                                    curve: Curves.easeOut,
                                  )
                                  .slideX(
                                    begin: 0.1,
                                    end: 0,
                                    curve: Curves.easeOutCubic,
                                  );
                            },
                          ),
                        ),
                        SizedBox(height: 16.h),
                        Text(
                              l10n.dashboard_recent,
                              style: AppTextStyles.manrope(
                                fontSize: 14.sp,
                                color: palette.textDark,
                                fontWeight: FontWeight.w600,
                              ),
                            )
                            .animate(delay: 140.ms)
                            .fadeIn(duration: 240.ms, curve: Curves.easeOut),
                        SizedBox(height: 12.h),
                        Column(
                          children: [
                            () {
                              final now = DateTime.now();
                              final today = DateTime(
                                now.year,
                                now.month,
                                now.day,
                              );
                              final yesterday = today.subtract(
                                const Duration(days: 1),
                              );

                              final recentExpenses = expenses.where((e) {
                                final d = DateTime(
                                  e.date.year,
                                  e.date.month,
                                  e.date.day,
                                );
                                return d == today || d == yesterday;
                              }).toList();

                              return Column(
                                children: [
                                  for (
                                    int i = 0;
                                    i < recentExpenses.length;
                                    i++
                                  ) ...[
                                    Builder(
                                      builder: (_) {
                                        final expense = recentExpenses[i];
                                        final category = ExpenseCategories.byId(
                                          expense.categoryId,
                                        );

                                        return TransactionHistory(
                                              emoji: category.emoji,
                                              recipientName:
                                                  expense.title?.isNotEmpty ==
                                                      true
                                                  ? expense.title!
                                                  : expense.note?.isNotEmpty ==
                                                        true
                                                  ? expense.note!
                                                  : category.labelOf(l10n),
                                              time: DateFormatter.expenseDate(
                                                expense.date,
                                              ),
                                              moneySpent:
                                                  CurrencyFormatter.format(
                                                    cubit: currencyCubit,
                                                    amountInInr: expense.amount,
                                                  ),
                                              onTap: () {
                                                context.push(
                                                  '/transaction-detail',
                                                  extra: expense,
                                                );
                                              },
                                            )
                                            .animate(delay: (200 + i * 60).ms)
                                            .fadeIn(
                                              duration: 280.ms,
                                              curve: Curves.easeOut,
                                            )
                                            .slideY(
                                              begin: 0.08,
                                              end: 0,
                                              curve: Curves.easeOutCubic,
                                            );
                                      },
                                    ),
                                    if (i != recentExpenses.length - 1)
                                      SizedBox(height: 12.h),
                                  ],
                                  if (recentExpenses.isEmpty)
                                    Padding(
                                      padding: EdgeInsets.symmetric(
                                        vertical: 24.h,
                                      ),
                                      child: Center(
                                        child: Text(
                                          l10n.dashboard_noTransactionsToday,
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
                              );
                            }(),
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
        );
      },
    );
  }
}
