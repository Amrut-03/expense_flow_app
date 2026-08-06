import 'package:expense_flow_app/core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/expense_category.dart';
import '../../../../core/constants/payment_methods.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/neumorphic_styles.dart';
import '../../../../core/theme/theme_cubit.dart';
import '../../../../core/widgets/neu_app_bar.dart';
import '../../../../core/widgets/neu_icon_button.dart';
import '../../../../core/widgets/neu_snack_bar.dart';
import '../../../../core/widgets/neu_text_field.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../currency/presentation/cubit/currency_cubit.dart';
import '../../domain/entities/expense_entity.dart';
import '../bloc/expense_bloc.dart';
import '../bloc/expense_event.dart';
import '../bloc/expense_state.dart';

class EditTransactionScreen extends StatefulWidget {
  final ExpenseEntity expense;

  const EditTransactionScreen({super.key, required this.expense});

  @override
  State<EditTransactionScreen> createState() => _EditTransactionScreenState();
}

class _EditTransactionScreenState extends State<EditTransactionScreen> {
  late final TextEditingController _amountController;
  late final TextEditingController _titleController;
  late final TextEditingController _noteController;
  late int _selectedCategoryIndex;
  late String? _paymentMethod;
  bool _isSaving = false;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();

    final categories = ExpenseCategories.all;

    final categoryIndex = categories.indexWhere(
      (category) => category.id == widget.expense.categoryId,
    );

    _selectedCategoryIndex = categoryIndex == -1 ? 0 : categoryIndex;
    _paymentMethod = widget.expense.paymentMethod;
    _amountController = TextEditingController(text: _initialAmount());
    _titleController = TextEditingController(text: widget.expense.title ?? '');
    _noteController = TextEditingController(text: widget.expense.note ?? '');
  }

  String _initialAmount() {
    final converted = context.read<CurrencyCubit>().convertFromInr(
      widget.expense.amount,
    );

    return converted.toStringAsFixed(2);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _titleController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    final amount = double.tryParse(_amountController.text);

    if (amount == null || amount <= 0) {
      NeuSnackBar.show(
        context: context,
        message: l10n.addExpense_validAmount,
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

    final currencyCubit = context.read<CurrencyCubit>();
    final category = ExpenseCategories.all[_selectedCategoryIndex];

    final amountInInr = double.parse(
      currencyCubit
          .convertToInr(
            amount: amount,
            fromCurrency: currencyCubit.state.selected.code,
          )
          .toStringAsFixed(2),
    );

    final updated = ExpenseEntity(
      id: widget.expense.id,
      amount: amountInInr,
      currency: currencyCubit.state.selected.code,
      categoryId: category.id,
      note: _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim(),
      title: _titleController.text.trim().isEmpty
          ? null
          : _titleController.text.trim(),
      paymentMethod: _paymentMethod,
      serverId: widget.expense.serverId,
      date: widget.expense.date,
      createdAt: widget.expense.createdAt,
      updatedAt: DateTime.now(),
      lastSyncedAt: widget.expense.lastSyncedAt,
      version: widget.expense.version,
      syncStatus: widget.expense.syncStatus,
      isDeleted: widget.expense.isDeleted,
    );

    setState(() => _isSaving = true);

    context.read<ExpenseBloc>().add(UpdateExpenseEvent(updated));
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.watch<ThemeCubit>().state.palette;
    final currencyCubit = context.watch<CurrencyCubit>();

    return BlocConsumer<ExpenseBloc, ExpenseState>(
      listener: (context, state) {
        if (state is ExpenseLoaded && _isSaving) {
          _isSaving = false;

          NeuSnackBar.show(
            context: context,
            message:
                state.syncWarning ??
                AppLocalizations.of(context).editExpense_updated,
            type: state.syncWarning != null
                ? NeuSnackBarType.info
                : NeuSnackBarType.success,
          );

          context.pop();
        }

        if (state is ExpenseLoaded && _isDeleting) {
          _isDeleting = false;

          NeuSnackBar.show(
            context: context,
            message:
                state.syncWarning ??
                AppLocalizations.of(context).editExpense_deleted,
            type: state.syncWarning != null
                ? NeuSnackBarType.info
                : NeuSnackBarType.success,
          );

          context.go('/dashboard');
        }

        if (state is ExpenseFailure) {
          _isSaving = false;
          _isDeleting = false;

          NeuSnackBar.show(
            context: context,
            message: state.message,
            type: NeuSnackBarType.error,
          );
        }
      },
      builder: (context, state) {
        final loading = state is ExpenseLoading;
        final categories = ExpenseCategories.all;
        final l10n = AppLocalizations.of(context);

        return Scaffold(
          backgroundColor: palette.background,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: 8.h),
                  NeuAppBar(
                    title: l10n.editExpense_title,
                    onBack: () => context.pop(),
                    trailing: NeuIconButton(
                      icon: Icons.check,
                      onTap: loading ? null : _save,
                      loading: loading,
                    ),
                  ),
                  SizedBox(height: 24.h),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 4.h,
                    ),
                    decoration: NeuBox.inset(palette, radius: 14.r),
                    child: Row(
                      children: [
                        Text(
                          currencyCubit.state.selected.symbol,
                          style: AppTextStyles.manrope(
                            fontSize: 26.sp,
                            color: palette.textMuted,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: TextField(
                            controller: _amountController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            style: AppTextStyles.manrope(
                              fontSize: 30.sp,
                              fontWeight: FontWeight.bold,
                              color: palette.textDark,
                            ),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(
                                vertical: 14,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 24.h),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.addExpense_titleLabel,
                        style: AppTextStyles.manrope(
                          fontSize: 14.sp,
                          color: palette.textMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 10.h),
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(16.r),
                        decoration: NeuBox.inset(palette, radius: 16.r),
                        child: TextField(
                          controller: _titleController,
                          style: AppTextStyles.manrope(
                            fontSize: 15.sp,
                            color: palette.textDark,
                            fontWeight: FontWeight.w500,
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20.h),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.addExpense_categoryLabel,
                        style: AppTextStyles.manrope(
                          fontSize: 14.sp,
                          color: palette.textMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 10.h),
                      Wrap(
                        spacing: 10.w,
                        runSpacing: 10.h,
                        children: [
                          for (
                            int index = 0;
                            index < categories.length;
                            index++
                          )
                            _categoryChip(
                              palette,
                              categories[index],
                              _selectedCategoryIndex == index,
                              () => setState(
                                () => _selectedCategoryIndex = index,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 20.h),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.addExpense_paymentMethodLabel,
                        style: AppTextStyles.manrope(
                          fontSize: 14.sp,
                          color: palette.textMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 10.h),
                      Wrap(
                        spacing: 10.w,
                        runSpacing: 10.h,
                        children: [
                          for (final method in PaymentMethods.all)
                            _paymentChip(palette, method),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 20.h),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.addExpense_note,
                        style: AppTextStyles.manrope(
                          fontSize: 14.sp,
                          color: palette.textMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 12.h),
                      NeuTextField(
                        height: 90.h,
                        controller: _noteController,
                        hint: l10n.addExpense_noteHint,
                      ),
                      SizedBox(height: 6.h),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ValueListenableBuilder<TextEditingValue>(
                          valueListenable: _noteController,
                          builder: (context, value, _) {
                            return Text(
                              "${value.text.length}/200 *",
                              style: AppTextStyles.manrope(
                                fontSize: 11.sp,
                                color: palette.textDark.withValues(alpha: .5),
                              ),
                            );
                          },
                        ),
                      ),
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

  Widget _paymentChip(NeuPalette palette, String method) {
    final isSelected = _paymentMethod == method;
    final l10n = AppLocalizations.of(context);

    return _selectChip(
      palette: palette,
      emoji: PaymentMethods.emojis[method] ?? '💸',
      label: PaymentMethods.localizedLabel(l10n, method),
      isSelected: isSelected,
      onTap: () => setState(() => _paymentMethod = method),
    );
  }

  Widget _categoryChip(
    NeuPalette palette,
    ExpenseCategory category,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return _selectChip(
      palette: palette,
      emoji: category.emoji,
      label: category.labelOf(AppLocalizations.of(context)),
      isSelected: isSelected,
      onTap: onTap,
    );
  }

  Widget _selectChip({
    required NeuPalette palette,
    required String emoji,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
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
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 220),
            style: TextStyle(
              fontSize: 16.sp,
              color: isSelected ? palette.background : palette.textDark,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(emoji, style: TextStyle(fontSize: 18.sp)),
                SizedBox(width: 6.w),
                Text(
                  label,
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
      ),
    );
  }
}
