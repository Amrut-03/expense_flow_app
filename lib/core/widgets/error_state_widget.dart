import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/app_text_styles.dart';
import 'empty_state.dart';
import 'neu_button.dart';

/// Full-page neumorphic error state with an optional retry action.
class ErrorStateWidget extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const ErrorStateWidget({super.key, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: EmptyStateWidget(
          boxed: true,
          icon: Text('⚠️', style: AppTextStyles.manrope(fontSize: 32.sp)),
          title: 'Something went wrong',
          subtitle: message,
          action: onRetry == null
              ? null
              : SizedBox(
                  width: 160.w,
                  child: NeuButton(label: 'Retry', onTap: onRetry),
                ),
        ),
      ),
    );
  }
}
