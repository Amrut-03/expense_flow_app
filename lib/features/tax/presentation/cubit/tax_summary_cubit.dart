import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/logging/app_log_buffer.dart';
import '../../domain/entities/tax_section.dart';
import '../../domain/usecases/get_tax_summary_usecase.dart';

class TaxSummaryState extends Equatable {
  final FinancialYear year;
  final FinancialYear currentYear;
  final TaxSummary? summary;
  final bool loading;

  const TaxSummaryState({
    required this.year,
    required this.currentYear,
    this.summary,
    this.loading = true,
  });

  bool get canGoNext => year.startYear < currentYear.startYear;

  @override
  List<Object?> get props => [year, currentYear, summary, loading];
}

class TaxSummaryCubit extends Cubit<TaxSummaryState> {
  TaxSummaryCubit(this.getSummary, {DateTime Function()? now})
    : super(
        TaxSummaryState(
          year: FinancialYear.of((now ?? DateTime.now)()),
          currentYear: FinancialYear.of((now ?? DateTime.now)()),
        ),
      );

  final GetTaxSummaryUseCase getSummary;

  Future<void> load([FinancialYear? year]) async {
    final target = year ?? state.year;
    emit(
      TaxSummaryState(
        year: target,
        currentYear: state.currentYear,
        summary: target == state.year ? state.summary : null,
      ),
    );
    try {
      final summary = await getSummary(target);
      if (isClosed || state.year != target) return;
      emit(
        TaxSummaryState(
          year: target,
          currentYear: state.currentYear,
          summary: summary,
          loading: false,
        ),
      );
    } catch (e, st) {
      AppLogBuffer.instance.captureError('tax.summary', e, st);
      if (!isClosed) {
        emit(
          TaxSummaryState(
            year: target,
            currentYear: state.currentYear,
            summary: TaxSummary(year: target, sections: const []),
            loading: false,
          ),
        );
      }
    }
  }

  Future<void> previousYear() => load(state.year.previous);

  Future<void> nextYear() async {
    if (!state.canGoNext) return;
    await load(FinancialYear(state.year.startYear + 1));
  }
}
