import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/neumorphic_styles.dart';
import '../../../../core/theme/theme_cubit.dart';
import '../../../../core/widgets/neu_bottom_sheet.dart';
import '../../../../core/widgets/neu_button.dart';
import '../../../../core/widgets/neu_text_field.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/custom_category.dart';
import '../../domain/usecases/custom_category_usecases.dart';

abstract final class CategoryChoices {
  static const emojis = [
    '🏠', '🛒', '🧹', '💊', '🐶', '👶', '🎁', '💇', //
    '🍷', '☕', '🎮', '📱', '💻', '⛽', '🏋️', '🧾', //
    '🍼', '🙏', '🎉', '📦', '🧺', '🚕', '🏦', '🏷️',
  ];

  static const colors = [
    0xFF5E35B1, 0xFF3949AB, 0xFF039BE5, 0xFF00ACC1, 0xFF7CB342, //
    0xFFC0CA33, 0xFFFFB300, 0xFF6D4C41, 0xFF546E7A, 0xFFEC407A,
  ];
}

/// Bottom sheet to create a category, or edit [existing].
/// Resolves to the saved category, or `null` if dismissed.
class CategoryEditorSheet extends StatefulWidget {
  const CategoryEditorSheet._({this.existing});

  final CustomCategory? existing;

  static Future<CustomCategory?> show(
    BuildContext context, {
    CustomCategory? existing,
  }) {
    return NeuBottomSheet.show<CustomCategory>(
      context: context,
      isScrollControlled: true,
      builder: (_) => CategoryEditorSheet._(existing: existing),
    );
  }

  @override
  State<CategoryEditorSheet> createState() => _CategoryEditorSheetState();
}

class _CategoryEditorSheetState extends State<CategoryEditorSheet> {
  late final TextEditingController _name;
  late String _emoji;
  late int _color;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _name = TextEditingController(text: existing?.label ?? '');
    _emoji = existing?.emoji ?? CategoryChoices.emojis.first;
    _color = existing?.colorValue ?? CategoryChoices.colors.first;
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final existing = widget.existing;
      CustomCategory saved;
      if (existing == null) {
        saved = await sl<CreateCustomCategoryUseCase>()(
          label: _name.text,
          emoji: _emoji,
          colorValue: _color,
        );
      } else {
        await sl<UpdateCustomCategoryUseCase>()(
          existing,
          label: _name.text,
          emoji: _emoji,
          colorValue: _color,
        );
        saved = existing.copyWith(
          label: _name.text.trim(),
          emoji: _emoji,
          colorValue: _color,
        );
      }
      if (mounted) Navigator.of(context).pop(saved);
    } on CategoryValidationException catch (e) {
      setState(() {
        _saving = false;
        _error = switch (e.reason) {
          CategoryValidationError.emptyName => l10n.categories_errorEmpty,
          CategoryValidationError.nameTooLong => l10n.categories_errorTooLong,
          CategoryValidationError.duplicateName =>
            l10n.categories_errorDuplicate,
          CategoryValidationError.tooMany => l10n.categories_errorTooMany,
        };
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.watch<ThemeCubit>().state.palette;
    final l10n = AppLocalizations.of(context);

    Widget sectionLabel(String text) => Padding(
      padding: EdgeInsets.only(bottom: 10.h, top: 18.h),
      child: Text(
        text,
        style: AppTextStyles.manrope(
          fontSize: 13.sp,
          fontWeight: FontWeight.w600,
          color: palette.textDark,
        ),
      ),
    );

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 24.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SheetDragHandle(),
            SizedBox(height: 16.h),
            Text(
              widget.existing == null
                  ? l10n.categories_newTitle
                  : l10n.categories_editTitle,
              style: AppTextStyles.manrope(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: palette.textDark,
              ),
            ),
            sectionLabel(l10n.categories_nameLabel),
            NeuTextField(
              height: 56.h,
              controller: _name,
              hint: l10n.categories_nameHint,
              maxLength: CustomCategoryRules.maxLabelLength,
            ),
            if (_error != null) ...[
              SizedBox(height: 8.h),
              Text(
                _error!,
                style: AppTextStyles.manrope(
                  fontSize: 12.sp,
                  color: palette.danger,
                ),
              ),
            ],
            sectionLabel(l10n.categories_iconLabel),
            Wrap(
              spacing: 8.w,
              runSpacing: 8.h,
              children: [
                for (final emoji in CategoryChoices.emojis)
                  GestureDetector(
                    onTap: () => setState(() => _emoji = emoji),
                    child: Container(
                      width: 40.w,
                      height: 40.w,
                      alignment: Alignment.center,
                      decoration: NeuBox.raised(
                        palette,
                        radius: 12.r,
                        bgColor: _emoji == emoji
                            ? palette.accent
                            : palette.background,
                      ),
                      child: Text(emoji, style: TextStyle(fontSize: 18.sp)),
                    ),
                  ),
              ],
            ),
            sectionLabel(l10n.categories_colorLabel),
            Wrap(
              spacing: 10.w,
              runSpacing: 10.h,
              children: [
                for (final color in CategoryChoices.colors)
                  GestureDetector(
                    onTap: () => setState(() => _color = color),
                    child: Container(
                      width: 32.w,
                      height: 32.w,
                      decoration: BoxDecoration(
                        color: Color(color),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _color == color
                              ? palette.textDark
                              : Colors.transparent,
                          width: 2.5,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: 24.h),
            SizedBox(
              width: double.infinity,
              child: NeuButton(
                label: l10n.common_save,
                loading: _saving,
                onTap: _saving ? null : _save,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
