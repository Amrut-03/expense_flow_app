import 'package:equatable/equatable.dart';

/// Neutral input describing a single transaction.
///
/// Defined inside the AI module so chunk generation never depends on the
/// transaction feature. The caller maps its own entities onto this DTO
/// before invoking a chunk generator.
class TransactionChunkInput extends Equatable {
  /// Identifier of the source transaction.
  final String id;

  /// Merchant or payee name (for example `Dominos`).
  final String merchant;

  /// Human-readable category label (for example `Food`).
  final String categoryName;

  /// Transaction amount in INR.
  final double amount;

  /// Transaction date.
  final DateTime date;

  /// Optional user note attached to the transaction.
  final String? note;

  const TransactionChunkInput({
    required this.id,
    required this.merchant,
    required this.categoryName,
    required this.amount,
    required this.date,
    this.note,
  });

  @override
  List<Object?> get props => [id, merchant, categoryName, amount, date, note];
}

/// Neutral input describing a monthly spending summary.
class MonthlySummaryChunkInput extends Equatable {
  /// Identifier of the summary (for example `monthly-2026-08`).
  final String id;

  /// First day of the month the summary covers.
  final DateTime month;

  /// Total spent during [month] in INR.
  final double totalSpent;

  /// Number of transactions that make up the summary.
  final int transactionCount;

  /// Total spent during the previous month, when available.
  final double? previousMonthSpent;

  const MonthlySummaryChunkInput({
    required this.id,
    required this.month,
    required this.totalSpent,
    required this.transactionCount,
    this.previousMonthSpent,
  });

  @override
  List<Object?> get props => [
    id,
    month,
    totalSpent,
    transactionCount,
    previousMonthSpent,
  ];
}

/// Neutral input describing a weekly spending summary.
class WeeklySummaryChunkInput extends Equatable {
  /// Identifier of the summary.
  final String id;

  /// First day of the covered week.
  final DateTime weekStart;

  /// Last day of the covered week.
  final DateTime weekEnd;

  /// Total spent during the week in INR.
  final double totalSpent;

  /// Number of transactions that make up the summary.
  final int transactionCount;

  /// Total spent during the previous week, when available.
  final double? previousWeekSpent;

  const WeeklySummaryChunkInput({
    required this.id,
    required this.weekStart,
    required this.weekEnd,
    required this.totalSpent,
    required this.transactionCount,
    this.previousWeekSpent,
  });

  @override
  List<Object?> get props => [
    id,
    weekStart,
    weekEnd,
    totalSpent,
    transactionCount,
    previousWeekSpent,
  ];
}

/// Neutral input describing a category-level spending summary.
class CategorySummaryChunkInput extends Equatable {
  /// Identifier of the summary (for example `food-2026-08`).
  final String id;

  /// Human-readable category label (for example `Food`).
  final String categoryName;

  /// Total spent in the category during the period, in INR.
  final double totalSpent;

  /// Number of transactions in the category during the period.
  final int transactionCount;

  /// First day of the covered period.
  final DateTime periodStart;

  /// Last day of the covered period.
  final DateTime periodEnd;

  const CategorySummaryChunkInput({
    required this.id,
    required this.categoryName,
    required this.totalSpent,
    required this.transactionCount,
    required this.periodStart,
    required this.periodEnd,
  });

  @override
  List<Object?> get props => [
    id,
    categoryName,
    totalSpent,
    transactionCount,
    periodStart,
    periodEnd,
  ];
}

/// Neutral input describing a budget for a single category.
class BudgetChunkInput extends Equatable {
  /// Identifier of the budget.
  final String id;

  /// Human-readable category label the budget applies to (for example
  /// `Food`).
  final String categoryName;

  /// Amount already spent against the budget, in INR.
  final double spent;

  /// Budget limit in INR.
  final double limit;

  /// Billing/plan period: `monthly`, `quarterly`, `yearly`, or empty.
  final String period;

  const BudgetChunkInput({
    required this.id,
    required this.categoryName,
    required this.spent,
    required this.limit,
    this.period = 'monthly',
  });

  @override
  List<Object?> get props => [id, categoryName, spent, limit, period];
}

/// Neutral input describing a savings goal.
class SavingsGoalChunkInput extends Equatable {
  /// Identifier of the goal.
  final String id;

  /// Human-readable goal name (for example `Vacation Goal`).
  final String name;

  /// Amount already saved towards the goal, in INR.
  final double saved;

  /// Target amount of the goal, in INR.
  final double target;

  /// Optional date the goal should be reached by.
  final DateTime? targetDate;

  const SavingsGoalChunkInput({
    required this.id,
    required this.name,
    required this.saved,
    required this.target,
    this.targetDate,
  });

  @override
  List<Object?> get props => [id, name, saved, target, targetDate];
}

/// Neutral input describing a recurring subscription.
class SubscriptionChunkInput extends Equatable {
  /// Identifier of the subscription.
  final String id;

  /// Human-readable subscription name (for example `Netflix`).
  final String name;

  /// Billing amount per cycle, in INR.
  final double amount;

  /// Billing cycle: `monthly`, `yearly`, or empty.
  final String billingCycle;

  /// Date of the next charge.
  final DateTime nextBillingDate;

  const SubscriptionChunkInput({
    required this.id,
    required this.name,
    required this.amount,
    required this.billingCycle,
    required this.nextBillingDate,
  });

  @override
  List<Object?> get props => [id, name, amount, billingCycle, nextBillingDate];
}

/// Neutral input describing a full chunk-regeneration pass after a single
/// transaction changed.
///
/// Carries the affected transaction together with pre-computed monthly,
/// weekly, and category summaries. The AI module never queries the
/// transaction feature; the caller computes the summaries and passes them
/// here.
class TransactionChunkRegenerationInput extends Equatable {
  /// Identifier of the affected transaction. Used to remove its chunk when
  /// [transaction] is `null` (the transaction was deleted).
  final String transactionId;

  /// The affected transaction, or `null` when it was deleted.
  final TransactionChunkInput? transaction;

  /// Pre-computed monthly summary for the transaction's month.
  final MonthlySummaryChunkInput monthlySummary;

  /// Pre-computed weekly summary for the transaction's week.
  final WeeklySummaryChunkInput weeklySummary;

  /// Pre-computed category summary for the transaction's category.
  final CategorySummaryChunkInput categorySummary;

  const TransactionChunkRegenerationInput({
    required this.transactionId,
    required this.transaction,
    required this.monthlySummary,
    required this.weeklySummary,
    required this.categorySummary,
  });

  @override
  List<Object?> get props => [
    transactionId,
    transaction,
    monthlySummary,
    weeklySummary,
    categorySummary,
  ];
}
