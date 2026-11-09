import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/neumorphic_styles.dart';
import '../../../../core/theme/theme_cubit.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/spending_event.dart';

/// "Part of: [None] [🪔 Diwali] [✈️ Bangkok]" chips on the expense forms.
/// Renders nothing when there are no [events] to offer.
class EventTagPicker extends StatelessWidget {
  const EventTagPicker({
    super.key,
    required this.events,
    required this.selected,
    required this.onChanged,
    this.suggested = false,
    this.enabled = true,
  });

  final List<SpendingEvent> events;
  final SpendingEvent? selected;
  final ValueChanged<SpendingEvent?> onChanged;

  /// Shows a hint that the selection was made automatically.
  final bool suggested;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) return const SizedBox.shrink();
    final palette = context.watch<ThemeCubit>().state.palette;
    final l10n = AppLocalizations.of(context);

    Widget chip(String label, bool isSelected, VoidCallback onTap) =>
        GestureDetector(
          onTap: enabled ? onTap : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
            decoration: NeuBox.raised(
              palette,
              radius: 14.r,
              bgColor: isSelected ? palette.accent : palette.background,
            ),
            child: Text(
              label,
              style: AppTextStyles.manrope(
                fontSize: 13.sp,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? palette.onAccent : palette.textDark,
              ),
            ),
          ),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              l10n.events_partOf,
              style: AppTextStyles.manrope(
                fontSize: 14.sp,
                color: palette.textDark,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (suggested && selected != null) ...[
              SizedBox(width: 8.w),
              Text(
                l10n.events_autoSelected,
                style: AppTextStyles.manrope(
                  fontSize: 11.sp,
                  color: palette.textMuted,
                ),
              ),
            ],
          ],
        ),
        SizedBox(height: 12.h),
        Wrap(
          spacing: 10.w,
          runSpacing: 10.h,
          children: [
            chip(l10n.events_none, selected == null, () => onChanged(null)),
            for (final e in events)
              chip(
                '${e.emoji} ${e.name}'
                '${e.currency != null ? ' · ${e.currency}' : ''}',
                selected?.id == e.id,
                () => onChanged(e),
              ),
          ],
        ),
      ],
    );
  }
}
