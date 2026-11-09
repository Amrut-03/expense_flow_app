import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/logging/app_log_buffer.dart';
import '../../domain/services/monthly_statement.dart';
import '../../domain/usecases/export_usecases.dart';

enum ReportsBusy { none, pdf, csv }

class ReportsState extends Equatable {
  final DateTime month;
  final DateTime currentMonth;
  final MonthlyStatement? statement;
  final ExportRange range;
  final ReportsBusy busy;

  const ReportsState({
    required this.month,
    required this.currentMonth,
    this.statement,
    this.range = ExportRange.thisMonth,
    this.busy = ReportsBusy.none,
  });

  bool get canGoNext => month.isBefore(currentMonth);

  ReportsState copyWith({
    DateTime? month,
    MonthlyStatement? statement,
    bool clearStatement = false,
    ExportRange? range,
    ReportsBusy? busy,
  }) {
    return ReportsState(
      month: month ?? this.month,
      currentMonth: currentMonth,
      statement: clearStatement ? null : (statement ?? this.statement),
      range: range ?? this.range,
      busy: busy ?? this.busy,
    );
  }

  @override
  List<Object?> get props => [month, currentMonth, statement, range, busy];
}

/// Result of an export: a file path to share, `null` when there was nothing
/// to export, or an error.
sealed class ExportResult {
  const ExportResult();
}

class ExportReady extends ExportResult {
  final String path;
  const ExportReady(this.path);
}

class ExportEmpty extends ExportResult {
  const ExportEmpty();
}

class ExportFailed extends ExportResult {
  const ExportFailed();
}

class ReportsCubit extends Cubit<ReportsState> {
  ReportsCubit({
    required this.getStatement,
    required this.exportPdf,
    required this.exportCsv,
    DateTime Function()? now,
  }) : super(_initial((now ?? DateTime.now)()));

  static ReportsState _initial(DateTime now) {
    final month = DateTime(now.year, now.month);
    return ReportsState(month: month, currentMonth: month);
  }

  final GetMonthlyStatementUseCase getStatement;
  final ExportStatementPdfUseCase exportPdf;
  final ExportExpensesCsvUseCase exportCsv;

  Future<void> load([DateTime? month]) async {
    final target = month ?? state.month;
    emit(state.copyWith(month: target, clearStatement: target != state.month));
    try {
      final statement = await getStatement(target);
      if (!isClosed && state.month == target) {
        emit(state.copyWith(statement: statement));
      }
    } catch (e, st) {
      AppLogBuffer.instance.captureError('reports.statement', e, st);
    }
  }

  Future<void> previousMonth() =>
      load(DateTime(state.month.year, state.month.month - 1));

  Future<void> nextMonth() async {
    if (!state.canGoNext) return;
    await load(DateTime(state.month.year, state.month.month + 1));
  }

  void selectRange(ExportRange range) => emit(state.copyWith(range: range));

  Future<ExportResult> buildPdf() async {
    if (state.statement?.isEmpty ?? true) return const ExportEmpty();
    return _run(ReportsBusy.pdf, () => exportPdf(state.month));
  }

  Future<ExportResult> buildCsv() =>
      _run(ReportsBusy.csv, () => exportCsv(state.range));

  Future<ExportResult> _run(
    ReportsBusy kind,
    Future<String?> Function() job,
  ) async {
    if (state.busy != ReportsBusy.none) return const ExportFailed();
    emit(state.copyWith(busy: kind));
    try {
      final path = await job();
      return path == null ? const ExportEmpty() : ExportReady(path);
    } catch (e, st) {
      AppLogBuffer.instance.captureError('reports.export.${kind.name}', e, st);
      return const ExportFailed();
    } finally {
      if (!isClosed) emit(state.copyWith(busy: ReportsBusy.none));
    }
  }
}
