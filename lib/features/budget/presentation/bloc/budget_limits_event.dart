import 'package:equatable/equatable.dart';
import '../../domain/entities/budget_entity.dart';

abstract class BudgetLimitsEvent extends Equatable {
  const BudgetLimitsEvent();

  @override
  List<Object?> get props => [];
}

class LoadBudgetLimits extends BudgetLimitsEvent {
  const LoadBudgetLimits();
}

class SetBudgetLimits extends BudgetLimitsEvent {
  final Map<String, double> limits;
  final Map<String, BudgetPeriod> periods;

  const SetBudgetLimits(this.limits, {this.periods = const {}});

  @override
  List<Object?> get props => [limits, periods];
}

class BudgetRemoteUpdated extends BudgetLimitsEvent {
  const BudgetRemoteUpdated();
}
