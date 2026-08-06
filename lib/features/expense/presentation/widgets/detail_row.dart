import 'package:expense_flow_app/core/theme/app_text_styles.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_colors.dart';

class DetailRow extends StatelessWidget {
  final NeuPalette palette;
  final IconData icon;
  final String label;
  final String value;
  const DetailRow({
    super.key,
    required this.palette,
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 14.h),
      child: Row(
        children: [
          Icon(icon, color: palette.textMuted, size: 18.sp),
          SizedBox(width: 10.w),
          Text(
            label,
            style: AppTextStyles.manrope(
              fontSize: 15.sp,
              color: palette.textMuted,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: AppTextStyles.manrope(
              fontSize: 15.sp,
              color: palette.textDark,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
