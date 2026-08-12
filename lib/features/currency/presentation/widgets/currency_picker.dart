import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/theme_cubit.dart';
import '../../../../core/widgets/neu_bottom_sheet.dart';
import '../../../../core/widgets/sync_warning_banner.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/app_currency.dart';
import '../cubit/currency_cubit.dart';
import '../cubit/currency_state.dart';

class CurrencyPicker {
  const CurrencyPicker._();

  static Future<void> show(BuildContext context) {
    final cubit = context.read<CurrencyCubit>();
    final l10n = AppLocalizations.of(context);

    return NeuBottomSheet.show<void>(
      context: context,
      builder: (sheetContext) {
        return BlocBuilder<CurrencyCubit, CurrencyState>(
          bloc: cubit,
          builder: (context, currencyState) {
            final selected = currencyState.selected;
            final palette = context.read<ThemeCubit>().state.palette;

            return SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SheetDragHandle(),
                  SizedBox(height: 20.h),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    child: Text(
                      l10n.settings_changeCurrency,
                      style: AppTextStyles.manrope(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.bold,
                        color: palette.textDark,
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    child: Text(
                      l10n.settings_chooseCurrency,
                      style: AppTextStyles.manrope(
                        fontSize: 14.sp,
                        color: palette.textDark.withValues(alpha: .6),
                      ),
                    ),
                  ),
                  SizedBox(height: 12.h),
                  if (currencyState.rateError != null) ...[
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20.w),
                      child: SyncWarningBanner(
                        message: currencyState.rateError!,
                      ),
                    ),
                    SizedBox(height: 12.h),
                  ],
                  Flexible(
                    child: ListView(
                      shrinkWrap: true,
                      children: supportedCurrencies.map((currency) {
                        return ListTile(
                          title: Text(
                            '${currency.symbol}  ${currency.code}',
                            style: AppTextStyles.manrope(
                              color: palette.textDark,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          trailing: currency.code == selected.code
                              ? Icon(
                                  Icons.check_circle_rounded,
                                  color: palette.accent,
                                )
                              : null,
                          onTap: () async {
                            await cubit.changeCurrency(currency);
                            if (sheetContext.mounted) {
                              sheetContext.pop();
                            }
                          },
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}