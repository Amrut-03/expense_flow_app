import 'package:expense_flow_app/core/theme/app_text_styles.dart';
import 'package:expense_flow_app/core/widgets/concave_decoration.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/theme_cubit.dart';

class NeuTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool obscureText;
  final TextInputType? keyboardType;
  final Widget? suffixIcon;
  final Widget? prefixIcon;
  final String? Function(String?)? validator;
  final double height;
  final double radius;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final ValueChanged<String>? onFieldSubmitted;
  final FocusNode? focusNode;
  final bool readOnly;
  final VoidCallback? onTap;
  final int maxLines;
  final ValueChanged<String>? onChanged;
  final int? maxLength;

  const NeuTextField({
    super.key,
    required this.controller,
    required this.hint,
    this.obscureText = false,
    this.keyboardType,
    this.height = 40,
    this.suffixIcon,
    this.prefixIcon,
    this.validator,
    this.textInputAction,
    this.autofillHints,
    this.onFieldSubmitted,
    this.onChanged,
    this.focusNode,
    this.readOnly = false,
    this.onTap,
    this.maxLines = 1,
    this.maxLength,
    this.radius = 16,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.watch<ThemeCubit>().state.palette;
    return Container(
      height: height.h,
      decoration: ConcaveDecoration(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius.r),
        ),
        depth: -6, // positive = pressed-in look; negative = raised look
        colors: [palette.shadowDark, palette.shadowLight],
        opacity: .8, // tweak until it matches your neumorphic style
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        validator: validator,
        textInputAction: textInputAction,
        autofillHints: autofillHints,
        onFieldSubmitted: onFieldSubmitted,
        focusNode: focusNode,
        readOnly: readOnly,
        onTap: onTap,
        onChanged: onChanged,
        cursorColor: palette.shadowDark,
        cursorHeight: 15.h,
        maxLines: obscureText ? 1 : maxLines,
        maxLength: maxLength,
        // The default counter is suppressed; callers render their own
        // localized counter (e.g. "42/280").
        buildCounter: maxLength == null
            ? null
            : (context, {required int currentLength, required bool isFocused, int? maxLength}) =>
                  const SizedBox.shrink(),
        style: AppTextStyles.manrope(fontSize: 13.sp, color: palette.textDark),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: AppTextStyles.manrope(
            fontSize: 12.sp,
            color: palette.textMuted,
          ),
          prefixIcon: prefixIcon,
          suffixIcon: suffixIcon,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: 16.w,
            vertical: 14.h,
          ),
        ),
      ),
    );
  }
}
