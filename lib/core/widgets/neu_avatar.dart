import 'package:expense_flow_app/core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/neumorphic_styles.dart';
import '../theme/theme_cubit.dart';

class NeuAvatar extends StatelessWidget {
  final String? photoUrl;
  final String initial;
  final double size;

  const NeuAvatar({
    super.key,
    required this.photoUrl,
    required this.initial,
    this.size = 68,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.watch<ThemeCubit>().state.palette;
    final photo = photoUrl?.trim();
    final hasPhoto = photo != null && photo.isNotEmpty;

    return Container(
      width: size.w,
      height: size.w,
      alignment: Alignment.center,
      decoration: NeuBox.raised(palette, radius: (size / 2).r),
      clipBehavior: Clip.antiAlias,
      child: hasPhoto
          ? ClipOval(
              child: Image.network(
                photo,
                width: (size - 4).w,
                height: (size - 4).w,
                fit: BoxFit.cover,
                errorBuilder: (context, _, _) => _fallback(palette),
              ),
            )
          : _fallback(palette),
    );
  }

  Widget _fallback(dynamic palette) {
    return Text(
      initial,
      style: AppTextStyles.manrope(
        fontSize: (size * 0.28).sp,
        fontWeight: FontWeight.w600,
        color: palette.textDark,
      ),
    );
  }
}
