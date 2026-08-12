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
import '../../../currency/presentation/cubit/currency_cubit.dart';
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
  final _noteController = TextEditingController();
  bool _isSaving = false;
  String? _selectedCategoryId;
  String? _paymentMethod;
  bool _wasTicking = true;

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
    _noteController.clear();

    setState(() {
      _selectedCategoryId = null;
      _paymentMethod = null;
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _titleController.dispose();
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

    final amountInInr = double.parse(
      currencyCubit
          .convertToInr(
            amount: enteredAmount,
            fromCurrency: currencyCubit.state.selected.code,
          )
          .toStringAsFixed(2),
    );

    _isSaving = true;

    context.read<ExpenseBloc>().add(
      AddExpenseEvent(
        amount: amountInInr,
        currency: currencyCubit.state.selected.code,
        categoryId: _selectedCategoryId!,
        note: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
        title: _titleController.text.trim(),
        paymentMethod: _paymentMethod,
        date: DateTime.now(),
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
                            NeuIconButton(
                              icon: Icons.check,
                              onTap: loading ? null : _saveExpense,
                              loading: loading,
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
                          child: AmountInput(controller: _amountController),
                        )
                        .animate(delay: 120.ms)
                        .fadeIn(duration: 280.ms, curve: Curves.easeOut)
                        .slideY(
                          begin: 0.06,
                          end: 0,
                          curve: Curves.easeOutCubic,
                        ),
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
                          l10n.addExpense_categoryLabel,
                          style: AppTextStyles.manrope(
                            fontSize: 14.sp,
                            color: palette.textDark,
                            fontWeight: FontWeight.w600,
                          ),
                        )
                        .animate(delay: 200.ms)
                        .fadeIn(duration: 260.ms, curve: Curves.easeOut),
                    SizedBox(height: 12.h),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: ExpenseCategories.all.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        crossAxisSpacing: 12.w,
                        childAspectRatio: 0.8,
                      ),
                      itemBuilder: (context, index) {
                        final category = ExpenseCategories.all[index];

                        return Center(
                          child: SizedBox(
                            width: 70.w,
                            height: 70.h,
                            child:
                                CategoryTile(
                                      emoji: category.emoji,
                                      isSelected:
                                          _selectedCategoryId == category.id,
                                      onTap: () {
                                        setState(() {
                                          _selectedCategoryId = category.id;
                                        });
                                      },
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
