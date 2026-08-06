import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/neumorphic_styles.dart';
import '../theme/theme_cubit.dart';

class NeuIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final bool loading;
  final Color? bgColor;

  const NeuIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.loading = false,
    this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.watch<ThemeCubit>().state.palette;
    final background = bgColor ?? palette.accent;
    final contrast = background.computeLuminance() > 0.5
        ? palette.textDark
        : palette.background;

    return GestureDetector(
      onTap: loading ? null : onTap,
      child: Container(
        width: 44.w,
        height: 44.h,
        alignment: Alignment.center,
        decoration: NeuBox.raised(palette, radius: 16.r, bgColor: background),
        child: loading
            ? SizedBox(
                width: 18.h,
                height: 18.h,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: contrast,
                ),
              )
            : Icon(icon, size: 18.h, color: contrast),
      ),
    );
  }
}
