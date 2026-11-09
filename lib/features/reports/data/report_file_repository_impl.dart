import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../../tax/domain/usecases/get_tax_summary_usecase.dart';
import '../domain/repositories/report_file_repository.dart';
import '../domain/services/expense_csv_builder.dart';
import '../domain/services/monthly_statement.dart';
import 'pdf_statement_renderer.dart';

/// Writes reports to the app's temp directory, ready for the share sheet.
/// Files there are cleared by the OS, so nothing lingers unencrypted.
class ReportFileRepositoryImpl implements ReportFileRepository {
  ReportFileRepositoryImpl({PdfStatementRenderer? renderer})
    : _renderer = renderer ?? PdfStatementRenderer();

  final PdfStatementRenderer _renderer;

  Future<File> _file(String name) async {
    final dir = Directory('${(await getTemporaryDirectory()).path}/reports');
    if (!await dir.exists()) await dir.create(recursive: true);
    return File('${dir.path}/$name');
  }

  @override
  Future<String> writeStatementPdf(MonthlyStatement statement) async {
    final m = statement.month;
    final file = await _file(
      'expenseflow_statement_${m.year}-${m.month.toString().padLeft(2, '0')}.pdf',
    );
    await file.writeAsBytes(await _renderer.render(statement), flush: true);
    return file.path;
  }

  @override
  Future<String> writeCsv(String fileName, String csv) async {
    final file = await _file(fileName);
    await file.writeAsString(csv, encoding: utf8, flush: true);
    return file.path;
  }

  @override
  Future<String> writeTaxSummaryCsv(TaxSummary summary) => writeCsv(
    'expenseflow_tax_${summary.year.label.replaceAll(' ', '_').toLowerCase()}.csv',
    ExpenseCsvBuilder.buildTaxSummary(summary),
  );
}
