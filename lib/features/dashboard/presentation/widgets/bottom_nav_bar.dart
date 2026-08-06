import 'package:expense_flow_app/core/di/injection_container.dart';
import 'package:expense_flow_app/core/theme/neumorphic_styles.dart';
import 'package:expense_flow_app/core/theme/theme_cubit.dart';
import 'package:expense_flow_app/features/notifications/presentation/bloc/notifications_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/widgets/concave_decoration.dart';
import 'package:go_router/go_router.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTabChanged;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTabChanged,
  });

  static const _emojis = ['🏠', '📊', '➕', '🤖', '⚙️'];

  @override
  Widget build(BuildContext context) {
    final palette = context.watch<ThemeCubit>().state.palette;

    return Container(
      height: 70.h,
      padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 10),
      decoration: NeuBox.raised(palette, radius: 16.r),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final tabWidth = constraints.maxWidth / _emojis.length;

          return Stack(
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 380),
                curve: Curves.easeOutBack,
                left: tabWidth * currentIndex,
                top: 0,
                bottom: 0,
                width: tabWidth,
                child: Center(
                  child: TweenAnimationBuilder<double>(
                    key: ValueKey(currentIndex),
                    tween: Tween(begin: 0.5, end: 1.0),
                    duration: const Duration(milliseconds: 380),
                    curve: Curves.easeOutBack,
                    builder: (context, scale, child) {
                      return Transform.scale(scale: scale, child: child);
                    },
                    child: Container(
                      width: 42.w,
                      height: 42.w,
                      decoration: BoxDecoration(
                        color: palette.accent,
                        borderRadius: BorderRadius.circular(12.r),
                        boxShadow: [
                          BoxShadow(
                            color: palette.accent.withValues(alpha: .4),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Row(
                children: List.generate(_emojis.length, (index) {
                  return Expanded(
                    child: Center(
                      child: _NavTab(
                        emoji: _emojis[index],
                        isSelected: index == currentIndex,
                        onTap: () => onTabChanged(index),
                      ),
                    ),
                  );
                }),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _NavTab extends StatefulWidget {
  final String emoji;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavTab({
    required this.emoji,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_NavTab> createState() => _NavTabState();
}

class _NavTabState extends State<_NavTab> {
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
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: widget.isSelected
              ? Padding(
                  key: const ValueKey('selected'),
                  padding: EdgeInsets.symmetric(
                    horizontal: 10.w,
                    vertical: 8.h,
                  ),
                  child: Text(widget.emoji, style: TextStyle(fontSize: 20.sp)),
                )
              : Container(
                  key: const ValueKey('unselected'),
                  decoration: ConcaveDecoration(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    depth: -8,
                    colors: [palette.shadowDark, palette.shadowLight],
                    opacity: .5,
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: 10.w,
                    vertical: 8.h,
                  ),
                  child: Text(widget.emoji, style: TextStyle(fontSize: 16.sp)),
                ),
        ),
      ),
    );
  }
}

class ScaffoldWithNavBar extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const ScaffoldWithNavBar({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    final palette = context.watch<ThemeCubit>().state.palette;

    return BlocProvider(
      create: (_) => sl<NotificationsCubit>()..load(),
      child: Scaffold(
        backgroundColor: palette.background,
        body: SafeArea(child: navigationShell),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(24.w, 0, 24.w, 12.h),
            child: BottomNavBar(
              currentIndex: navigationShell.currentIndex,
              onTabChanged: (index) => navigationShell.goBranch(
                index,
                // tapping the already-active tab pops it back to its root
                // (e.g. clears a pushed detail screen within that tab)
                initialLocation: index == navigationShell.currentIndex,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
