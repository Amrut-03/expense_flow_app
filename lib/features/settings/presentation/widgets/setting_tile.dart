import 'package:expense_flow_app/core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/neumorphic_styles.dart';
import '../../../../core/theme/theme_cubit.dart';

class SettingsTile extends StatelessWidget {
  final String emoji;
  final String label;
  final Widget trailing;
  final VoidCallback? onTap;

  const SettingsTile({
    super.key,
    required this.emoji,
    required this.label,
    required this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.watch<ThemeCubit>().state.palette;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        decoration: NeuBox.raised(palette, radius: 20.r),
        child: Row(
          children: [
            Container(
              width: 40.w,
              height: 40.w,
              alignment: Alignment.center,
              decoration: NeuBox.raised(palette, radius: 12.r),
              child: Text(emoji, style: TextStyle(fontSize: 16.sp)),
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.manrope(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: palette.textDark,
                ),
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }
}

class ValueChevron extends StatelessWidget {
  final String value;

  const ValueChevron({super.key, required this.value});

  @override
  Widget build(BuildContext context) {
    final palette = context.watch<ThemeCubit>().state.palette;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: AppTextStyles.manrope(
            fontSize: 13.sp,
            color: palette.textDark.withValues(alpha: .5),
          ),
        ),
        SizedBox(width: 4.w),
        Icon(
          Icons.chevron_right,
          color: palette.textDark.withValues(alpha: .4),
          size: 18.sp,
        ),
      ],
    );
  }
}
