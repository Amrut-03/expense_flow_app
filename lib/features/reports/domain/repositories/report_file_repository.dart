import '../../../tax/domain/usecases/get_tax_summary_usecase.dart';
import '../services/monthly_statement.dart';

/// Writes report files to device storage and returns their paths.
abstract interface class ReportFileRepository {
  Future<String> writeStatementPdf(MonthlyStatement statement);
  Future<String> writeCsv(String fileName, String csv);
  Future<String> writeTaxSummaryCsv(TaxSummary summary);
}
