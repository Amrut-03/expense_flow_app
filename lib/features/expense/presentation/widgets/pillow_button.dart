import 'package:expense_flow_app/core/theme/app_text_styles.dart';
import 'package:expense_flow_app/core/theme/app_colors.dart';
import 'package:expense_flow_app/core/theme/neumorphic_styles.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class PillowButton extends StatelessWidget {
  final Color bgColor;
  final IconData icon;
  final String label;
  final Color textColor;
  final VoidCallback onTap;
  final NeuPalette palette;

  const PillowButton({
    super.key,
    required this.bgColor,
    required this.icon,
    required this.label,
    required this.textColor,
    required this.onTap,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: NeuBox.raised(palette, radius: 16.r, bgColor: palette.accent),
      child: GestureDetector(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 16.h),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: textColor, size: 18.sp),
              SizedBox(width: 8.w),
              Text(
                label,
                style: AppTextStyles.manrope(
                  color: textColor,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
