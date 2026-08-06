import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/neumorphic_styles.dart';
import '../../../../core/theme/theme_cubit.dart';

class CategoryTile extends StatefulWidget {
  final String emoji;
  final bool isSelected;
  final VoidCallback onTap;

  const CategoryTile({
    super.key,
    required this.emoji,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<CategoryTile> createState() => _CategoryTileState();
}

class _CategoryTileState extends State<CategoryTile> {
  bool _isPressed = false;

  void _setPressed(bool value) => setState(() => _isPressed = value);

  @override
  Widget build(BuildContext context) {
    final palette = context.watch<ThemeCubit>().state.palette;

    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => _setPressed(true),
      onTapCancel: () => _setPressed(false),
      onTapUp: (_) => _setPressed(false),
      child: AnimatedScale(
        scale: _isPressed ? 0.85 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: TweenAnimationBuilder<double>(
          key: ValueKey(widget.isSelected),
          tween: Tween(begin: widget.isSelected ? 0.5 : 1.0, end: 1.0),
          duration: const Duration(milliseconds: 380),
          curve: Curves.easeOutBack,
          builder: (context, scale, child) {
            return Transform.scale(scale: scale, child: child);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            height: 70.h,
            width: 70.w,
            padding: EdgeInsets.symmetric(vertical: 12.h),
            decoration: NeuBox.raised(
              palette,
              radius: 24.r,
              bgColor: widget.isSelected ? palette.accent : palette.background,
            ),
            child: Center(
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 220),
                style: TextStyle(
                  fontSize: 20.sp,
                  color: widget.isSelected
                      ? palette.background
                      : palette.textDark,
                ),
                child: Text(widget.emoji),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
