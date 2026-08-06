import 'package:expense_flow_app/core/theme/app_text_styles.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/neumorphic_styles.dart';
import '../../../../core/theme/theme_cubit.dart';

class CategoriesTile extends StatelessWidget {
  final double height;
  final double width;
  final String emoji;
  final String label;
  final VoidCallback? onTap;

  const CategoriesTile({
    super.key,
    this.height = 90,
    this.width = 100,
    required this.emoji,
    this.label = "",
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.watch<ThemeCubit>().state.palette;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: height.h,
        width: width.w,
        padding: EdgeInsets.symmetric(vertical: 12.h),
        decoration: NeuBox.raised(palette, radius: 24.r),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: TextStyle(fontSize: 20.sp)),
            Text(
              label,
              style: AppTextStyles.manrope(
                fontSize: 12.sp,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF7B8FA1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
