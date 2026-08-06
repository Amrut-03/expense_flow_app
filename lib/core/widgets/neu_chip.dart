import 'package:expense_flow_app/core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/neumorphic_styles.dart';
import '../theme/theme_cubit.dart';

class NeuChip extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final IconData trailingIcon;

  const NeuChip({
    super.key,
    required this.label,
    this.onTap,
    this.trailingIcon = Icons.arrow_drop_down,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.watch<ThemeCubit>().state.palette;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
        decoration: NeuBox.raised(palette, radius: 8.r),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: AppTextStyles.manrope(
                fontSize: 12.sp,
                color: palette.textDark.withValues(alpha: .6),
              ),
            ),
            SizedBox(width: 4.w),
            Icon(
              trailingIcon,
              size: 14.h,
              color: palette.textDark.withValues(alpha: .4),
            ),
          ],
        ),
      ),
    );
  }
}
