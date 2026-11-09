import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/expense_category.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/neumorphic_styles.dart';
import '../../../../core/theme/theme_cubit.dart';
import '../../../../core/widgets/neu_app_bar.dart';
import '../../../../core/widgets/neu_button.dart';
import '../../../../core/widgets/neu_loading.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../currency/presentation/cubit/currency_cubit.dart';
import '../../../currency/presentation/util/currency_formatter.dart';
import '../../domain/usecases/export_usecases.dart';
import '../cubit/reports_cubit.dart';
import '../share_report.dart';

/// Monthly PDF statement and CSV (Excel) export.
class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = context.watch<ThemeCubit>().state.palette;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(24.w, 10.h, 24.w, 0),
              child: NeuAppBar(
                title: l10n.reports_title,
                onBack: () => context.pop(),
              ),
            ),
            Expanded(
              child: BlocBuilder<ReportsCubit, ReportsState>(
                builder: (context, state) => ListView(
                  padding: EdgeInsets.fromLTRB(24.w, 20.h, 24.w, 24.h),
                  children: [
                    _StatementCard(state: state),
                    SizedBox(height: 16.h),
                    _CsvCard(state: state),
                    SizedBox(height: 16.h),
                    _TaxLink(palette: palette),
                    SizedBox(height: 12.h),
                    Text(
                      l10n.reports_privacyNote,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.manrope(
                        fontSize: 11.sp,
                        color: palette.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatementCard extends StatelessWidget {
  const _StatementCard({required this.state});

  final ReportsState state;

  @override
  Widget build(BuildContext context) {
    final palette = context.watch<ThemeCubit>().state.palette;
    final currency = context.watch<CurrencyCubit>();
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<ReportsCubit>();
    final statement = state.statement;
    String money(double inr) =>
        CurrencyFormatter.format(cubit: currency, amountInInr: inr);

    return Container(
      padding: EdgeInsets.all(20.r),
      decoration: NeuBox.raised(palette, radius: 18.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _title(palette, '📄  ${l10n.reports_statementTitle}'),
          SizedBox(height: 4.h),
          _subtitle(palette, l10n.reports_statementHint),
          SizedBox(height: 12.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: Icon(Icons.chevron_left, color: palette.textDark),
                onPressed: cubit.previousMonth,
              ),
              Text(
                DateFormat.yMMMM(l10n.localeName).format(state.month),
                style: AppTextStyles.manrope(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w600,
                  color: palette.textDark,
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.chevron_right,
                  color: state.canGoNext
                      ? palette.textDark
                      : palette.textMuted.withValues(alpha: .3),
                ),
                onPressed: state.canGoNext ? cubit.nextMonth : null,
              ),
            ],
          ),
          SizedBox(height: 8.h),
          if (statement == null)
            const Center(child: NeuLoading())
          else if (statement.isEmpty)
            Center(child: _subtitle(palette, l10n.reports_noExpensesMonth))
          else
            Row(
              children: [
                _stat(palette, l10n.reports_total, money(statement.total)),
                _stat(
                  palette,
                  l10n.reports_transactions,
                  '${statement.expenses.length}',
                ),
                _stat(
                  palette,
                  l10n.reports_topCategory,
                  () {
                    final top = ExpenseCategories.byId(
                      statement.byCategory.first.key,
                    );
                    return '${top.emoji} ${top.labelOf(l10n)}';
                  }(),
                ),
              ],
            ),
          SizedBox(height: 16.h),
          SizedBox(
            width: double.infinity,
            child: NeuButton(
              label: l10n.reports_sharePdf,
              icon: Icons.picture_as_pdf_outlined,
              loading: state.busy == ReportsBusy.pdf,
              onTap: statement == null || statement.isEmpty
                  ? null
                  : () async {
                      final result = await cubit.buildPdf();
                      if (context.mounted) {
                        await shareExport(
                          context,
                          result,
                          subject: l10n.reports_statementTitle,
                        );
                      }
                    },
            ),
          ),
        ],
      ),
    );
  }
}

class _CsvCard extends StatelessWidget {
  const _CsvCard({required this.state});

  final ReportsState state;

  String _rangeLabel(AppLocalizations l10n, ExportRange r) => switch (r) {
    ExportRange.thisMonth => l10n.reports_rangeThisMonth,
    ExportRange.lastMonth => l10n.reports_rangeLastMonth,
    ExportRange.financialYear => l10n.reports_rangeFinancialYear,
    ExportRange.allTime => l10n.reports_rangeAllTime,
  };

  @override
  Widget build(BuildContext context) {
    final palette = context.watch<ThemeCubit>().state.palette;
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<ReportsCubit>();

    return Container(
      padding: EdgeInsets.all(20.r),
      decoration: NeuBox.raised(palette, radius: 18.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _title(palette, '📊  ${l10n.reports_csvTitle}'),
          SizedBox(height: 4.h),
          _subtitle(palette, l10n.reports_csvHint),
          SizedBox(height: 14.h),
          Wrap(
            spacing: 10.w,
            runSpacing: 10.h,
            children: [
              for (final range in ExportRange.values)
                GestureDetector(
                  onTap: () => cubit.selectRange(range),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: EdgeInsets.symmetric(
                      vertical: 10.h,
                      horizontal: 14.w,
                    ),
                    decoration: NeuBox.raised(
                      palette,
                      radius: 14.r,
                      bgColor: state.range == range
                          ? palette.accent
                          : palette.background,
                    ),
                    child: Text(
                      _rangeLabel(l10n, range),
                      style: AppTextStyles.manrope(
                        fontSize: 13.sp,
                        fontWeight: state.range == range
                            ? FontWeight.w600
                            : FontWeight.w500,
                        color: state.range == range
                            ? palette.background
                            : palette.textDark,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 16.h),
          SizedBox(
            width: double.infinity,
            child: NeuButton(
              label: l10n.reports_exportCsv,
              icon: Icons.table_chart_outlined,
              loading: state.busy == ReportsBusy.csv,
              onTap: () async {
                final result = await cubit.buildCsv();
                if (context.mounted) {
                  await shareExport(
                    context,
                    result,
                    subject: l10n.reports_csvTitle,
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TaxLink extends StatelessWidget {
  const _TaxLink({required this.palette});

  final NeuPalette palette;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return GestureDetector(
      onTap: () => context.push('/tax-summary'),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
        decoration: NeuBox.raised(palette, radius: 18.r),
        child: Row(
          children: [
            Text('🧾', style: TextStyle(fontSize: 18.sp)),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                l10n.reports_taxLink,
                style: AppTextStyles.manrope(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: palette.textDark,
                ),
              ),
            ),
            Icon(Icons.chevron_right, color: palette.textMuted),
          ],
        ),
      ),
    );
  }
}

Widget _title(NeuPalette palette, String text) => Text(
  text,
  style: AppTextStyles.manrope(
    fontSize: 15.sp,
    fontWeight: FontWeight.bold,
    color: palette.textDark,
  ),
);

Widget _subtitle(NeuPalette palette, String text) => Text(
  text,
  style: AppTextStyles.manrope(fontSize: 12.sp, color: palette.textMuted),
);

Widget _stat(NeuPalette palette, String label, String value) => Expanded(
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: AppTextStyles.manrope(fontSize: 11.sp, color: palette.textMuted),
      ),
      SizedBox(height: 4.h),
      Text(
        value,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTextStyles.manrope(
          fontSize: 14.sp,
          fontWeight: FontWeight.bold,
          color: palette.textDark,
        ),
      ),
    ],
  ),
);
