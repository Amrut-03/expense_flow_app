import 'package:expense_flow_app/core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/neumorphic_styles.dart';
import '../theme/theme_cubit.dart';

class EmptyStateWidget extends StatelessWidget {
  final Widget icon;
  final String title;
  final String? subtitle;
  final Widget? action;
  final bool boxed;

  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
    this.boxed = false,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.watch<ThemeCubit>().state.palette;

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        icon,
        SizedBox(height: 14.h),
        Text(
          title,
          textAlign: TextAlign.center,
          style: AppTextStyles.manrope(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            color: palette.textDark,
          ),
        ),
        if (subtitle != null) ...[
          SizedBox(height: 6.h),
          Text(
            subtitle!,
            textAlign: TextAlign.center,
            style: AppTextStyles.manrope(
              fontSize: 13.sp,
              height: 1.4,
              color: palette.textMuted,
            ),
          ),
        ],
        if (action != null) ...[SizedBox(height: 20.h), action!],
      ],
    );

    if (boxed) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 48.h, horizontal: 24.w),
        decoration: NeuBox.inset(palette, radius: 20.r),
        child: content,
      );
    }
    return content;
  }
}
