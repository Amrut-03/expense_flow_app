import 'package:expense_flow_app/core/theme/app_text_styles.dart';
import 'package:expense_flow_app/core/theme/neumorphic_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../theme/theme_cubit.dart';

class NeuAppBar extends StatelessWidget {
  final String title;
  final VoidCallback? onBack;
  final Widget? trailing;

  const NeuAppBar({super.key, required this.title, this.onBack, this.trailing});

  @override
  Widget build(BuildContext context) {
    final palette = context.watch<ThemeCubit>().state.palette;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (onBack != null)
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onBack,
            child: Container(
              width: 44.w,
              height: 44.h,
              alignment: Alignment.center,
              decoration: NeuBox.raised(
                palette,
                radius: 16.r,
                bgColor: palette.background,
              ),
              child: Center(
                child: Icon(
                  Icons.arrow_back_ios_new,
                  size: 18.h,
                  color: palette.textDark,
                ),
              ),
            ),
          )
        else
          SizedBox(width: 44.w, height: 44.h),
        Text(
          title,
          style: AppTextStyles.manrope(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: palette.textDark,
          ),
        ),
        trailing ?? SizedBox(width: 44.w, height: 44.h),
      ],
    );
  }
}
