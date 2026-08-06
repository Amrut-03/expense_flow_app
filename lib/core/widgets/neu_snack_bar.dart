import 'package:expense_flow_app/core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/neumorphic_styles.dart';
import '../theme/theme_cubit.dart';

enum NeuSnackBarType { success, error, info }

class NeuSnackBar {
  static void show({
    required BuildContext context,
    required String message,
    NeuSnackBarType type = NeuSnackBarType.info,
    Duration? duration,
  }) {
    final palette = context.read<ThemeCubit>().state.palette;

    final (icon, color) = switch (type) {
      NeuSnackBarType.success => (Icons.check_circle_rounded, palette.success),
      NeuSnackBarType.error => (Icons.cancel_rounded, palette.danger),
      NeuSnackBarType.info => (Icons.info_rounded, palette.accent),
    };

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.transparent,
          elevation: 0,
          duration: duration ?? const Duration(seconds: 3),
          margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          padding: EdgeInsets.zero,
          content: Container(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
            decoration: NeuBox.raised(palette, radius: 16.r),
            child: Row(
              children: [
                Container(
                  width: 40.r,
                  height: 40.r,
                  decoration: NeuBox.inset(palette, radius: 13.r),
                  child: Icon(icon, color: color, size: 20.sp),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    message,
                    style: AppTextStyles.manrope(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w500,
                      color: palette.textDark,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
  }
}
