import 'package:expense_flow_app/core/theme/app_text_styles.dart';
import 'package:expense_flow_app/core/theme/neumorphic_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../theme/theme_cubit.dart';

enum NeuButtonVariant { primary, secondary }

class NeuButton extends StatefulWidget {
  final String label;
  final VoidCallback? onTap;
  final bool loading;
  final NeuButtonVariant variant;
  final Color? bgColor;
  final IconData? icon;

  const NeuButton({
    super.key,
    required this.label,
    required this.onTap,
    this.loading = false,
    this.variant = NeuButtonVariant.primary,
    this.bgColor,
    this.icon,
  });

  @override
  State<NeuButton> createState() => _NeuButtonState();
}

class _NeuButtonState extends State<NeuButton> {
  bool _isPressed = false;

  void _setPressed(bool value) {
    if (widget.onTap == null || widget.loading) return;
    setState(() => _isPressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.watch<ThemeCubit>().state.palette;
    final isDisabled = widget.onTap == null || widget.loading;
    final background =
        widget.bgColor ??
        (widget.variant == NeuButtonVariant.primary
            ? palette.background
            : palette.shadowDarkLight);
    final labelColor = widget.bgColor != null
        ? (widget.bgColor!.computeLuminance() > 0.5
              ? palette.textDark
              : palette.background)
        : widget.variant == NeuButtonVariant.primary
        ? palette.textDark
        : palette.textMuted;

    return GestureDetector(
      onTap: widget.loading ? null : widget.onTap,
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      child: Opacity(
        opacity: isDisabled ? 0.5 : 1,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          height: 44,
          alignment: Alignment.center,
          decoration: _isPressed
              ? NeuBox.pressed(palette, radius: 16, bgColor: background)
              : NeuBox.raised(palette, radius: 16, bgColor: background),
          child: widget.loading
              ? SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: labelColor,
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (widget.icon != null) ...[
                      Icon(widget.icon, size: 18, color: labelColor),
                      SizedBox(width: 8),
                    ],
                    Text(
                      widget.label,
                      style: AppTextStyles.manrope(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: labelColor,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
