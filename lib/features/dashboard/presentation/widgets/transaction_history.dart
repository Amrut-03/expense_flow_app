import 'package:expense_flow_app/core/theme/app_text_styles.dart';
import 'package:expense_flow_app/core/theme/neumorphic_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/theme_cubit.dart';
import '../../../../core/widgets/concave_decoration.dart';

class TransactionHistory extends StatelessWidget {
  final String emoji;
  final String recipientName;
  final String time;
  final String moneySpent;
  final VoidCallback? onTap;

  const TransactionHistory({
    super.key,
    required this.emoji,
    required this.recipientName,
    required this.time,
    required this.moneySpent,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.watch<ThemeCubit>().state.palette;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        decoration: NeuBox.raised(palette, radius: 20.r),
        padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 10.h),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Row(
                children: [
                  Container(
                    decoration: ConcaveDecoration(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      depth:
                          -8, // positive = pressed-in look; negative = raised look
                      colors: [palette.shadowDark, palette.shadowLight],
                      opacity:
                          .5, // tweak until it matches your neumorphic style
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: 10.w,
                      vertical: 8.h,
                    ),
                    child: Text(emoji, style: TextStyle(fontSize: 20.sp)),
                  ),
                  SizedBox(width: 15.w),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          recipientName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.manrope(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                            color: palette.textDark,
                          ),
                        ),
                        Text(
                          time,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.manrope(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w500,
                            color: palette.textDark.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 12.w),
            Flexible(
              child: Text(
                moneySpent,
                textAlign: TextAlign.right,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.manrope(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w800,
                  color: palette.textDark,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
