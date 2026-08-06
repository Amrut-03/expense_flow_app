import 'package:equatable/equatable.dart';
import '../../domain/entities/budget_entity.dart';

sealed class BudgetLimitsState extends Equatable {
  const BudgetLimitsState();

  bool get hasAnyBudget => false;

  @override
  List<Object?> get props => [];
}

class BudgetLimitsInitial extends BudgetLimitsState {
  const BudgetLimitsInitial();
}

class BudgetLimitsLoading extends BudgetLimitsState {
  const BudgetLimitsLoading();
}

class BudgetLimitsError extends BudgetLimitsState {
  final String message;

  const BudgetLimitsError(this.message);

  @override
  List<Object?> get props => [message];
}

class BudgetLimitsLoaded extends BudgetLimitsState {
  final Map<String, double> limits;
  final Map<String, BudgetPeriod> periods;

  const BudgetLimitsLoaded(this.limits, {this.periods = const {}});

  @override
  bool get hasAnyBudget => limits.values.any((v) => v > 0);

  @override
  List<Object?> get props => [limits, periods];
}
