import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/logging/app_log_buffer.dart';
import '../../../expense/domain/entities/expense_entity.dart';
import '../../../expense/domain/repositories/expense_repository.dart';
import '../../domain/services/year_in_review.dart';

class WrappedState extends Equatable {
  final bool loading;
  final List<int> years;
  final YearInReview? review;

  /// Replace amounts with "•••" so the card can be shared privately.
  final bool hideAmounts;

  const WrappedState({
    this.loading = true,
    this.years = const [],
    this.review,
    this.hideAmounts = false,
  });

  WrappedState copyWith({YearInReview? review, bool? hideAmounts}) =>
      WrappedState(
        loading: false,
        years: years,
        review: review ?? this.review,
        hideAmounts: hideAmounts ?? this.hideAmounts,
      );

  @override
  List<Object?> get props => [loading, years, review, hideAmounts];
}

class WrappedCubit extends Cubit<WrappedState> {
  WrappedCubit(this.expenseRepository, {DateTime Function()? now})
    : _now = now ?? DateTime.now,
      super(const WrappedState());

  final ExpenseRepository expenseRepository;
  final DateTime Function() _now;
  List<ExpenseEntity> _expenses = const [];

  Future<void> load() async {
    try {
      _expenses = await expenseRepository.getExpenses();
      final years = YearInReview.availableYears(_expenses);
      emit(
        WrappedState(
          loading: false,
          years: years,
          review: years.isEmpty
              ? null
              : YearInReview.compute(_expenses, years.first, _now()),
        ),
      );
    } catch (e, st) {
      AppLogBuffer.instance.captureError('wrapped.load', e, st);
      emit(const WrappedState(loading: false));
    }
  }

  void selectYear(int year) => emit(
    state.copyWith(review: YearInReview.compute(_expenses, year, _now())),
  );

  void toggleHideAmounts() =>
      emit(state.copyWith(hideAmounts: !state.hideAmounts));
}
