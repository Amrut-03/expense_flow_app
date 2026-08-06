import 'package:expense_flow_app/core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/theme_cubit.dart';
import '../../../currency/presentation/cubit/currency_cubit.dart';
import '../../../currency/presentation/cubit/currency_state.dart';

class AmountInput extends StatefulWidget {
  final TextEditingController controller;

  const AmountInput({super.key, required this.controller});

  @override
  State<AmountInput> createState() => _AmountInputState();
}

class _AmountInputState extends State<AmountInput> {
  double _fontSize = 40.sp;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_updateFontSize);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_updateFontSize);
    super.dispose();
  }

  void _updateFontSize() {
    final length = widget.controller.text.length;
    double newSize;
    if (length <= 6) {
      newSize = 40;
    } else if (length <= 9) {
      newSize = 32;
    } else if (length <= 12) {
      newSize = 24;
    } else {
      newSize = 18;
    }
    if (newSize != _fontSize) {
      setState(() => _fontSize = newSize);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.watch<ThemeCubit>().state.palette;

    return Center(
      child: SizedBox(
        width: 210.w,
        height: 50.h,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            BlocBuilder<CurrencyCubit, CurrencyState>(
              builder: (context, state) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  height: (_fontSize).h,
                  child: Align(
                    alignment: Alignment.bottomRight,
                    child: AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 150),
                      style: AppTextStyles.manrope(
                        fontSize: (_fontSize * 0.5).sp,
                        fontWeight: FontWeight.w600,
                        color: palette.textDark.withValues(alpha: .5),
                      ),
                      child: Text(state.selected.symbol),
                    ),
                  ),
                );
              },
            ),
            Expanded(
              child: TextField(
                controller: widget.controller,
                showCursor: false,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                textAlign: TextAlign.left,
                inputFormatters: [
                  TextInputFormatter.withFunction((oldValue, newValue) {
                    final text = newValue.text;
                    if (text.isEmpty) return newValue;

                    if (!RegExp(r'^\d*\.?\d*$').hasMatch(text)) return oldValue;
                    if ('.'.allMatches(text).length > 1) return oldValue;

                    final parts = text.split('.');
                    final intPart = parts[0];
                    final decPart = parts.length > 1 ? parts[1] : '';

                    if (intPart.length > 6) return oldValue;
                    if (decPart.length > 2) return oldValue;

                    final parsed = double.tryParse(text);
                    if (parsed != null && parsed > 999999.99) return oldValue;

                    return newValue;
                  }),
                ],
                style: AppTextStyles.manrope(
                  fontSize: _fontSize.sp,
                  fontWeight: FontWeight.w600,
                  color: palette.textDark,
                ),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  isDense: true,
                  hintText: '00.00',
                  hintStyle: AppTextStyles.manrope(
                    fontSize: _fontSize.sp,
                    color: palette.textDark.withValues(alpha: .4),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
