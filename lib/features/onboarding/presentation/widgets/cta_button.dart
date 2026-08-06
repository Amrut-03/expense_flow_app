import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/neumorphic_styles.dart';
import '../../../../core/theme/theme_cubit.dart';

class CtaButton extends StatelessWidget {
  final String label;
  final bool isLast;
  final VoidCallback onTap;

  const CtaButton({
    super.key,
    required this.label,
    required this.isLast,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.watch<ThemeCubit>().state.palette;

    final text = Text(
      label,
      style: AppTextStyles.manrope(
        fontSize: 14.sp,
        fontWeight: FontWeight.w700,
        color: palette.onAccent,
      ),
    );

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        height: 54.h,
        alignment: Alignment.center,
        decoration: NeuBox.raised(
          palette,
          radius: 27.r,
        ).copyWith(color: palette.accent),
        child: isLast
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  text,
                  SizedBox(width: 8.w),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 18,
                    color: palette.onAccent,
                  ),
                ],
              )
            : text,
      ),
    );
  }
}
