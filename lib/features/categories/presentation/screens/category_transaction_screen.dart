import 'package:expense_flow_app/core/theme/app_text_styles.dart';
import 'package:expense_flow_app/core/theme/neumorphic_styles.dart';
import 'package:expense_flow_app/core/widgets/neu_bottom_sheet.dart';
import 'package:expense_flow_app/core/widgets/error_state_widget.dart';
import 'package:expense_flow_app/core/widgets/neu_loading.dart';
import 'package:expense_flow_app/core/widgets/neu_text_field.dart';
import 'package:expense_flow_app/core/widgets/sync_warning_banner.dart';
import 'package:expense_flow_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/expense_category.dart';
import '../../../../core/theme/theme_cubit.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../currency/presentation/cubit/currency_cubit.dart';
import '../../../currency/presentation/util/currency_formatter.dart';
import '../../../dashboard/presentation/widgets/transaction_history.dart';
import '../../../expense/domain/entities/expense_entity.dart';
import '../../../expense/presentation/bloc/expense_bloc.dart';
import '../../../expense/presentation/bloc/expense_event.dart';
import '../../../expense/presentation/bloc/expense_state.dart';

enum TransactionSort { newest, oldest, highestAmount, lowestAmount }

class CategoryTransactionScreen extends StatefulWidget {
  final String? categoryId;
  final String categoryName;
  final String categoryEmoji;
  const CategoryTransactionScreen({
    super.key,
    this.categoryId,
    required this.categoryName,
    required this.categoryEmoji,
  });

  @override
  State<CategoryTransactionScreen> createState() =>
      _CategoryTransactionScreenState();
}

class _CategoryTransactionScreenState extends State<CategoryTransactionScreen> {
  final _searchController = TextEditingController();
  late TransactionSort _sort = TransactionSort.newest;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.watch<ThemeCubit>().state.palette;
    final currencyCubit = context.watch<CurrencyCubit>();
    final l10n = AppLocalizations.of(context);

    Widget buildTransactionList(List<ExpenseEntity> expenses) {
      return Column(
        children: [
          for (int i = 0; i < expenses.length; i++) ...[
            Builder(
              builder: (_) {
                final expense = expenses[i];
                final category = ExpenseCategories.byId(expense.categoryId);

                return TransactionHistory(
                      emoji: category.emoji,
                      recipientName: expense.title?.isNotEmpty == true
                          ? expense.title!
                          : expense.note?.isNotEmpty == true
                          ? expense.note!
                          : category.labelOf(l10n),
                      time: DateFormatter.expenseDate(expense.date),
                      moneySpent: CurrencyFormatter.format(
                        cubit: currencyCubit,
                        amountInInr: expense.amount,
                      ),
                      onTap: () {
                        context.push('/transaction-detail', extra: expense);
                      },
                    )
                    .animate(delay: (i * 40).ms)
                    .fadeIn(duration: 260.ms, curve: Curves.easeOut)
                    .slideY(begin: 0.08, end: 0, curve: Curves.easeOutCubic);
              },
            ),
            if (i != expenses.length - 1) SizedBox(height: 12.h),
          ],
        ],
      );
    }

    return BlocBuilder<ExpenseBloc, ExpenseState>(
      builder: (context, state) {
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

        final categoryExpenses = expenses.where((expense) {
          if (widget.categoryId != null) {
            return expense.categoryId == widget.categoryId;
          }
          return ExpenseCategories.byId(expense.categoryId).labelOf(l10n) ==
              widget.categoryName;
        }).toList();

        final search = _searchController.text.trim().toLowerCase();

        List<ExpenseEntity> filteredExpenses = categoryExpenses.where((
          expense,
        ) {
          final category = ExpenseCategories.byId(expense.categoryId);

          final title = expense.title?.isNotEmpty == true
              ? expense.title!
              : expense.note?.isNotEmpty == true
              ? expense.note!
              : category.labelOf(l10n);

          return title.toLowerCase().contains(search) ||
              category.labelOf(l10n).toLowerCase().contains(search);
        }).toList();

        switch (_sort) {
          case TransactionSort.newest:
            filteredExpenses.sort((a, b) => b.date.compareTo(a.date));
            break;

          case TransactionSort.oldest:
            filteredExpenses.sort((a, b) => a.date.compareTo(b.date));
            break;

          case TransactionSort.highestAmount:
            filteredExpenses.sort((a, b) => b.amount.compareTo(a.amount));
            break;

          case TransactionSort.lowestAmount:
            filteredExpenses.sort((a, b) => a.amount.compareTo(b.amount));
            break;
        }

        final grouped = <DateTime, List<ExpenseEntity>>{};

        for (final expense in filteredExpenses) {
          final key = DateTime(
            expense.date.year,
            expense.date.month,
            expense.date.day,
          );

          grouped.putIfAbsent(key, () => []);
          grouped[key]!.add(expense);
        }

        final dates = grouped.keys.toList();

        if (_sort == TransactionSort.oldest) {
          dates.sort((a, b) => a.compareTo(b));
        } else {
          dates.sort((a, b) => b.compareTo(a));
        }

        final groupedExpenses = <DateTime, List<ExpenseEntity>>{};

        for (final expense in filteredExpenses) {
          final date = DateTime(
            expense.date.year,
            expense.date.month,
            expense.date.day,
          );

          groupedExpenses.putIfAbsent(date, () => []).add(expense);
        }

        String getSectionTitle(DateTime date) {
          final now = DateTime.now();

          final today = DateTime(now.year, now.month, now.day);
          final yesterday = today.subtract(const Duration(days: 1));

          final target = DateTime(date.year, date.month, date.day);

          if (target == today) return l10n.transaction_today;
          if (target == yesterday) return l10n.transaction_yesterday;

          return DateFormat('dd MMM yyyy').format(date);
        }

        return Scaffold(
          backgroundColor: palette.background,
          body: SafeArea(
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
                      InkWell(
                        onTap: () => context.pop(),
                        child: Container(
                          width: 44.w,
                          height: 44.h,
                          alignment: Alignment.center,
                          decoration: NeuBox.raised(
                            palette,
                            radius: 16.r,
                            bgColor: palette.background,
                          ),
                          child: Center(
                            child: Icon(
                              Icons.arrow_back_ios_new,
                              size: 18.h,
                              color: palette.textDark,
                            ),
                          ),
                        ),
                      ),
                      Text(
                        widget.categoryName,
                        style: AppTextStyles.manrope(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.bold,
                          color: palette.textDark,
                        ),
                      ),
                      Container(
                        width: 44.w,
                        height: 44.h,
                        alignment: Alignment.center,
                        decoration: NeuBox.raised(palette, radius: 16.r),
                        child: Center(
                          child: IconButton(
                            color: palette.textDark,
                            onPressed: () => {
                              NeuBottomSheet.show<void>(
                                context: context,
                                builder: (_) => Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const SheetDragHandle(),
                                    SizedBox(height: 8.h),
                                    ListTile(
                                      title: Text(l10n.transaction_newest),
                                      onTap: () {
                                        setState(() {
                                          _sort = TransactionSort.newest;
                                        });
                                        context.pop();
                                      },
                                    ),
                                    ListTile(
                                      title: Text(l10n.transaction_oldest),
                                      onTap: () {
                                        setState(() {
                                          _sort = TransactionSort.oldest;
                                        });
                                        context.pop();
                                      },
                                    ),
                                    ListTile(
                                      title: Text(
                                        l10n.transaction_highestAmount,
                                      ),
                                      onTap: () {
                                        setState(() {
                                          _sort = TransactionSort.highestAmount;
                                        });
                                        context.pop();
                                      },
                                    ),
                                    ListTile(
                                      title: Text(
                                        l10n.transaction_lowestAmount,
                                      ),
                                      onTap: () {
                                        setState(() {
                                          _sort = TransactionSort.lowestAmount;
                                        });
                                        context.pop();
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            },
                            icon: Icon(Icons.sort),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 24.h),
                  NeuTextField(
                    radius: 20.r,
                    controller: _searchController,
                    hint: l10n.transaction_searchHint,
                    onChanged: (_) {
                      setState(() {});
                    },
                  ),
                  if (state.syncWarning != null) ...[
                    SizedBox(height: 15.h),
                    SyncWarningBanner(message: state.syncWarning!),
                  ],
                  SizedBox(height: 15.h),
                  Text(
                    l10n.transaction_today,
                    style: AppTextStyles.manrope(
                      fontSize: 14.sp,
                      color: palette.textDark.withValues(alpha: .5),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Column(
                    children: [
                      for (final date in dates) ...[
                        Text(
                          getSectionTitle(date),
                          style: AppTextStyles.manrope(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: palette.textDark.withValues(alpha: .5),
                          ),
                        ),
                        SizedBox(height: 12.h),
                        buildTransactionList(groupedExpenses[date]!),
                        SizedBox(height: 20.h),
                      ],
                    ],
                  ),
                  SizedBox(height: 24.h),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
