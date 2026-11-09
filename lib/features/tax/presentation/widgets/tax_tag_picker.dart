import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/neumorphic_styles.dart';
import '../../../../core/theme/theme_cubit.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/tax_section.dart';
import '../tax_labels.dart';

/// "Tax deduction" chips for the add/edit expense forms.
class TaxTagPicker extends StatelessWidget {
  const TaxTagPicker({
    super.key,
    required this.selected,
    required this.onChanged,
    this.suggested = false,
    this.enabled = true,
    this.labelColor,
    this.labelWeight = FontWeight.w600,
  });

  final TaxSection? selected;
  final ValueChanged<TaxSection?> onChanged;

  /// Shows a "✨ Suggested" hint next to the label.
  final bool suggested;
  final bool enabled;
  final Color? labelColor;
  final FontWeight labelWeight;

  @override
  Widget build(BuildContext context) {
    final palette = context.watch<ThemeCubit>().state.palette;
    final l10n = AppLocalizations.of(context);
    final current = selected;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              l10n.tax_label,
              style: AppTextStyles.manrope(
                fontSize: 14.sp,
                color: labelColor ?? palette.textDark,
                fontWeight: labelWeight,
              ),
            ),
            if (suggested && current != null) ...[
              SizedBox(width: 8.w),
              Text(
                l10n.addExpense_categorySuggested,
                style: AppTextStyles.manrope(
                  fontSize: 12.sp,
                  color: palette.accent,
                  fontWeight: FontWeight.w600,
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
            _chip(
              palette,
              label: l10n.tax_none,
              isSelected: current == null,
              onTap: () => onChanged(null),
            ),
            for (final section in TaxSection.values)
              _chip(
                palette,
                label: section.chipLabel,
                isSelected: current == section,
                onTap: () => onChanged(section),
              ),
          ],
        ),
        if (current != null) ...[
          SizedBox(height: 8.h),
          Text(
            current.description(l10n),
            style: AppTextStyles.manrope(
              fontSize: 12.sp,
              color: palette.textMuted,
            ),
          ),
        ],
      ],
    );
  }

  Widget _chip(
    NeuPalette palette, {
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 14.w),
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
            color: isSelected ? palette.background : palette.textDark,
          ),
        ),
      ),
    );
  }
}
