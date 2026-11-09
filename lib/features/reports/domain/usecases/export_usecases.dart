import '../../../expense/domain/repositories/expense_repository.dart';
import '../../../tax/domain/entities/tax_section.dart';
import '../../../tax/domain/usecases/get_tax_summary_usecase.dart';
import '../repositories/report_file_repository.dart';
import '../services/expense_csv_builder.dart';
import '../services/monthly_statement.dart';

/// Range of expenses to export as CSV.
enum ExportRange { thisMonth, lastMonth, financialYear, allTime }

class GetMonthlyStatementUseCase {
  const GetMonthlyStatementUseCase(this.repository);
  final ExpenseRepository repository;

  Future<MonthlyStatement> call(DateTime month) async =>
      MonthlyStatement.compute(await repository.getExpenses(), month);
}

/// Renders [MonthlyStatement] as a PDF file; returns its path.
class ExportStatementPdfUseCase {
  const ExportStatementPdfUseCase({
    required this.getStatement,
    required this.files,
  });

  final GetMonthlyStatementUseCase getStatement;
  final ReportFileRepository files;

  Future<String> call(DateTime month) async =>
      files.writeStatementPdf(await getStatement(month));
}

/// Writes expenses in [ExportRange] to a CSV file; returns its path, or
/// `null` when there's nothing to export.
class ExportExpensesCsvUseCase {
  ExportExpensesCsvUseCase({
    required this.repository,
    required this.files,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final ExpenseRepository repository;
  final ReportFileRepository files;
  final DateTime Function() _now;

  Future<String?> call(ExportRange range) async {
    final now = _now();
    final (start, end, label) = bounds(range, now);
    final rows = (await repository.getExpenses()).where(
      (e) =>
          !e.isDeleted &&
          (start == null || !e.date.isBefore(start)) &&
          (end == null || e.date.isBefore(end)),
    );
    if (rows.isEmpty) return null;
    return files.writeCsv(
      'expenseflow_$label.csv',
      ExpenseCsvBuilder.build(rows),
    );
  }

  /// Inclusive start, exclusive end and a file-name label for [range].
  static (DateTime?, DateTime?, String) bounds(ExportRange range, DateTime now) {
    String ym(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}';
    switch (range) {
      case ExportRange.thisMonth:
        final s = DateTime(now.year, now.month);
        return (s, DateTime(now.year, now.month + 1), ym(s));
      case ExportRange.lastMonth:
        final s = DateTime(now.year, now.month - 1);
        return (s, DateTime(now.year, now.month), ym(s));
      case ExportRange.financialYear:
        final fy = FinancialYear.of(now);
        return (
          fy.start,
          fy.end,
          fy.label.replaceAll(' ', '_').toLowerCase(),
        );
      case ExportRange.allTime:
        return (null, null, 'all');
    }
  }
}

class ExportTaxSummaryCsvUseCase {
  const ExportTaxSummaryCsvUseCase(this.files);
  final ReportFileRepository files;

  Future<String> call(TaxSummary summary) => files.writeTaxSummaryCsv(summary);
}
