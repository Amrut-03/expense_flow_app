import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../theme/app_text_styles.dart';
import '../theme/neumorphic_styles.dart';
import '../theme/theme_cubit.dart';

/// Non-blocking notice shown when data was loaded/saved locally but the cloud
/// sync failed (e.g. offline). Rendered beneath the app bar.
class SyncWarningBanner extends StatelessWidget {
  const SyncWarningBanner({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final palette = context.watch<ThemeCubit>().state.palette;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
        decoration: NeuBox.raised(palette, radius: 12.r),
        child: Row(
          children: [
            Text('⚠️', style: AppTextStyles.manrope(fontSize: 14.sp)),
            SizedBox(width: 8.w),
            Expanded(
              child: Text(
                message,
                style: AppTextStyles.manrope(
                  fontSize: 12.sp,
                  color: palette.textDark.withValues(alpha: .8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
