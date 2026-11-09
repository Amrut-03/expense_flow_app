import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/expense_category.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/neumorphic_styles.dart';
import '../../../../core/theme/theme_cubit.dart';
import '../../../../core/widgets/neu_app_bar.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/custom_category.dart';
import '../../domain/repositories/category_repository.dart';
import '../../domain/usecases/custom_category_usecases.dart';
import '../widgets/category_editor_sheet.dart';

/// Lists built-in categories (read-only) and the user's own categories
/// (create, edit, archive).
class ManageCategoriesScreen extends StatefulWidget {
  const ManageCategoriesScreen({super.key});

  @override
  State<ManageCategoriesScreen> createState() => _ManageCategoriesScreenState();
}

class _ManageCategoriesScreenState extends State<ManageCategoriesScreen> {
  final _repository = sl<CategoryRepository>();
  StreamSubscription<void>? _changes;

  @override
  void initState() {
    super.initState();
    _changes = _repository.watch().listen((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _changes?.cancel();
    super.dispose();
  }

  Future<void> _archive(CustomCategory category) async {
    final l10n = AppLocalizations.of(context);
    final palette = context.read<ThemeCubit>().state.palette;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: palette.background,
        title: Text(
          l10n.categories_archiveTitle(category.label),
          style: AppTextStyles.manrope(
            color: palette.textDark,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          l10n.categories_archiveMessage,
          style: AppTextStyles.manrope(color: palette.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => dialogContext.pop(false),
            child: Text(
              l10n.common_cancel,
              style: AppTextStyles.manrope(color: palette.textMuted),
            ),
          ),
          TextButton(
            onPressed: () => dialogContext.pop(true),
            child: Text(
              l10n.common_delete,
              style: AppTextStyles.manrope(
                color: palette.accent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await sl<ArchiveCustomCategoryUseCase>()(category);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.watch<ThemeCubit>().state.palette;
    final l10n = AppLocalizations.of(context);
    final custom = _repository.getAll().where((c) => !c.isArchived).toList();

    Widget tile({
      required String emoji,
      required String label,
      required Color color,
      Widget? trailing,
      VoidCallback? onTap,
    }) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          decoration: NeuBox.raised(palette, radius: 18.r),
          child: Row(
            children: [
              Container(
                width: 40.w,
                height: 40.w,
                alignment: Alignment.center,
                decoration: NeuBox.raised(palette, radius: 12.r),
                child: Text(emoji, style: TextStyle(fontSize: 18.sp)),
              ),
              SizedBox(width: 12.w),
              Container(
                width: 10.w,
                height: 10.w,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  label,
                  style: AppTextStyles.manrope(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: palette.textDark,
                  ),
                ),
              ),
              ?trailing,
            ],
          ),
        ),
      );
    }

    Widget header(String text) => Padding(
      padding: EdgeInsets.only(top: 20.h, bottom: 10.h),
      child: Text(
        text,
        style: AppTextStyles.manrope(
          fontSize: 13.sp,
          fontWeight: FontWeight.w600,
          color: palette.textMuted,
        ),
      ),
    );

    return Scaffold(
      backgroundColor: palette.background,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: palette.accent,
        foregroundColor: palette.onAccent,
        onPressed: () => CategoryEditorSheet.show(context),
        icon: const Icon(Icons.add),
        label: Text(l10n.categories_add),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(24.w, 10.h, 24.w, 0),
              child: NeuAppBar(
                title: l10n.categories_title,
                onBack: () => context.pop(),
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(24.w, 0, 24.w, 96.h),
                children: [
                  header(l10n.categories_yours),
                  if (custom.isEmpty)
                    Text(
                      l10n.categories_emptyHint,
                      style: AppTextStyles.manrope(
                        fontSize: 13.sp,
                        color: palette.textMuted,
                      ),
                    ),
                  for (final c in custom) ...[
                    tile(
                      emoji: c.emoji,
                      label: c.label,
                      color: Color(c.colorValue),
                      onTap: () =>
                          CategoryEditorSheet.show(context, existing: c),
                      trailing: IconButton(
                        tooltip: l10n.common_delete,
                        icon: Icon(
                          Icons.delete_outline,
                          color: palette.textMuted,
                        ),
                        onPressed: () => _archive(c),
                      ),
                    ),
                    SizedBox(height: 10.h),
                  ],
                  header(l10n.categories_builtIn),
                  for (final c in ExpenseCategories.builtIn) ...[
                    tile(
                      emoji: c.emoji,
                      label: c.labelOf(l10n),
                      color: ExpenseCategories.colorFor(palette, c.id),
                    ),
                    SizedBox(height: 10.h),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
