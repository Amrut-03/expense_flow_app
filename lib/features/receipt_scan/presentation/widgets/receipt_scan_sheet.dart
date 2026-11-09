import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../../core/logging/app_log_buffer.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/theme_cubit.dart';
import '../../../../core/widgets/neu_bottom_sheet.dart';
import '../../../../core/widgets/neu_button.dart';
import '../../../../core/widgets/neu_loading.dart';
import '../../../../core/widgets/neu_snack_bar.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../currency/presentation/cubit/currency_cubit.dart';
import '../../../currency/presentation/util/currency_formatter.dart';
import '../../domain/entities/receipt_draft.dart';

/// Photo → on-device OCR → review → returns the draft to fill the form.
abstract final class ReceiptScanSheet {
  static Future<ReceiptDraft?> show(
    BuildContext context, {
    required Future<ReceiptDraft> Function(String imagePath) scan,
    ImagePicker? picker,
  }) async {
    final l10n = AppLocalizations.of(context);
    final source = await NeuBottomSheet.show<ImageSource>(
      context: context,
      builder: (sheetContext) {
        final palette = sheetContext.watch<ThemeCubit>().state.palette;
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 16.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SheetDragHandle(),
                SizedBox(height: 16.h),
                Text(
                  l10n.receipt_title,
                  style: AppTextStyles.manrope(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: palette.textDark,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  l10n.receipt_privacy,
                  style: AppTextStyles.manrope(
                    fontSize: 12.sp,
                    color: palette.textMuted,
                  ),
                ),
                SizedBox(height: 8.h),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    Icons.photo_camera_outlined,
                    color: palette.accent,
                  ),
                  title: Text(l10n.receipt_camera),
                  onTap: () =>
                      Navigator.of(sheetContext).pop(ImageSource.camera),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    Icons.photo_library_outlined,
                    color: palette.accent,
                  ),
                  title: Text(l10n.receipt_gallery),
                  onTap: () =>
                      Navigator.of(sheetContext).pop(ImageSource.gallery),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (source == null || !context.mounted) return null;

    XFile? photo;
    try {
      photo = await (picker ?? ImagePicker()).pickImage(
        source: source,
        maxWidth: 2000,
        imageQuality: 90,
      );
    } catch (e, st) {
      AppLogBuffer.instance.captureError('receipt.pick', e, st);
    }
    if (photo == null || !context.mounted) return null;

    ReceiptDraft? draft;
    final navigator = Navigator.of(context, rootNavigator: true);
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => PopScope(
        canPop: false,
        child: AlertDialog(
          content: Row(
            children: [
              const NeuLoading(),
              SizedBox(width: 16.w),
              Expanded(child: Text(l10n.receipt_reading)),
            ],
          ),
        ),
      ),
    );
    try {
      draft = await scan(photo.path);
    } catch (e, st) {
      AppLogBuffer.instance.captureError('receipt.scan', e, st);
    } finally {
      navigator.pop();
      // Camera shots are temp copies; don't keep receipt photos around.
      if (source == ImageSource.camera) {
        try {
          await File(photo.path).delete();
        } catch (_) {}
      }
    }
    if (!context.mounted) return null;

    if (draft == null || draft.isEmpty) {
      NeuSnackBar.show(
        context: context,
        message: l10n.receipt_unreadable,
        type: NeuSnackBarType.error,
      );
      return null;
    }
    return _review(context, draft);
  }

  static Future<ReceiptDraft?> _review(
    BuildContext context,
    ReceiptDraft draft,
  ) {
    final l10n = AppLocalizations.of(context);
    final currency = context.read<CurrencyCubit>();
    String money(double inr) =>
        CurrencyFormatter.format(cubit: currency, amountInInr: inr);
    final selected = List<bool>.filled(draft.items.length, true);

    return NeuBottomSheet.show<ReceiptDraft>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheet) {
          final palette = sheetContext.watch<ThemeCubit>().state.palette;
          final allSelected = selected.every((s) => s);
          final picked = [
            for (var i = 0; i < draft.items.length; i++)
              if (selected[i]) draft.items[i],
          ];
          // Some items unticked: the expense is just those (split bills).
          final amount = allSelected || picked.isEmpty
              ? draft.total
              : picked.fold<double>(0, (s, i) => s + i.amount);

          Widget row(String label, String? value) => Padding(
            padding: EdgeInsets.symmetric(vertical: 4.h),
            child: Row(
              children: [
                SizedBox(
                  width: 90.w,
                  child: Text(
                    label,
                    style: AppTextStyles.manrope(
                      fontSize: 12.sp,
                      color: palette.textMuted,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    value ?? l10n.receipt_notFound,
                    style: AppTextStyles.manrope(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: value == null
                          ? palette.textMuted
                          : palette.textDark,
                    ),
                  ),
                ),
              ],
            ),
          );

          return ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(sheetContext).height * .85,
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
                    l10n.receipt_reviewTitle,
                    style: AppTextStyles.manrope(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: palette.textDark,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  row(
                    l10n.receipt_total,
                    amount == null ? null : money(amount),
                  ),
                  row(l10n.receipt_merchant, draft.merchant),
                  row(
                    l10n.receipt_date,
                    draft.date == null
                        ? null
                        : DateFormat.yMMMd(l10n.localeName).format(draft.date!),
                  ),
                  if (draft.tax != null)
                    row(l10n.receipt_gst, money(draft.tax!)),
                  if (draft.items.isNotEmpty) ...[
                    SizedBox(height: 12.h),
                    Text(
                      l10n.receipt_items(draft.items.length),
                      style: AppTextStyles.manrope(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: palette.textDark,
                      ),
                    ),
                    Text(
                      l10n.receipt_itemsHint,
                      style: AppTextStyles.manrope(
                        fontSize: 11.sp,
                        color: palette.textMuted,
                      ),
                    ),
                    for (var i = 0; i < draft.items.length; i++)
                      CheckboxListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                        value: selected[i],
                        onChanged: (v) =>
                            setSheet(() => selected[i] = v ?? false),
                        title: Text(
                          draft.items[i].name,
                          style: AppTextStyles.manrope(
                            fontSize: 13.sp,
                            color: palette.textDark,
                          ),
                        ),
                        secondary: Text(
                          money(draft.items[i].amount),
                          style: AppTextStyles.manrope(
                            fontSize: 13.sp,
                            color: palette.textDark,
                          ),
                        ),
                      ),
                  ],
                  SizedBox(height: 16.h),
                  SizedBox(
                    width: double.infinity,
                    child: NeuButton(
                      label: l10n.receipt_use,
                      onTap: () => Navigator.of(sheetContext).pop(
                        ReceiptDraft(
                          total: amount,
                          merchant: draft.merchant,
                          date: draft.date,
                          tax: allSelected ? draft.tax : null,
                          items: picked,
                          paymentMethod: draft.paymentMethod,
                          categoryId: draft.categoryId,
                          lines: draft.lines,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
