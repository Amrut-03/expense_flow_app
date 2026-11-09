import 'package:equatable/equatable.dart';

import '../../../budget/domain/repositories/budget_repository.dart';
import '../../../budget/domain/repositories/budget_rollover_repository.dart';
import '../../../budget/domain/services/budget_expense_filter.dart';
import '../../../budget/domain/services/budget_progress_calculator.dart';
import '../../../budget/domain/services/rollover_calculator.dart';
import '../../../expense/domain/repositories/expense_repository.dart';
import '../../../recurring/domain/repositories/recurring_expense_repository.dart';
import '../../../recurring/domain/services/bill_reminder_planner.dart';
import '../services/weekly_digest_builder.dart';

class WeeklyDigest extends Equatable {
  final List<String> lines;

  /// True when the on-device model reworded the facts.
  final bool aiWritten;

  const WeeklyDigest({required this.lines, required this.aiWritten});

  String get body => lines.join('\n');

  @override
  List<Object?> get props => [lines, aiWritten];
}

/// Rewrites digest facts in a friendlier voice (on-device LLM).
abstract interface class DigestWriter {
  /// Whether rewriting is possible right now without downloads or a
  /// low-memory device.
  Future<bool> isAvailable();

  Future<String> rewrite(List<String> facts);
}

/// Persists the last model-written digest so the LLM runs at most once per
/// set of facts.
abstract interface class DigestCache {
  ({String factsKey, List<String> lines, DateTime writtenAt})? read();
  Future<void> write(String factsKey, List<String> lines, DateTime writtenAt);
}

/// Produces the weekly digest: always the deterministic facts, reworded by
/// the on-device model when available.
class GenerateWeeklyDigestUseCase {
  GenerateWeeklyDigestUseCase({
    required this.expenseRepository,
    required this.budgetRepository,
    required this.recurringRepository,
    this.writer,
    this.cache,
    this.rolloverRepository,
    this.budgetFilter,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  /// Re-running the model for every small data change wastes battery; facts
  /// that changed less than this long after the last rewrite use the
  /// template until the window passes.
  static const minRewriteInterval = Duration(hours: 12);

  static const rewriteTimeout = Duration(seconds: 60);

  final ExpenseRepository expenseRepository;
  final BudgetRepository budgetRepository;
  final RecurringExpenseRepository recurringRepository;
  final DigestWriter? writer;
  final DigestCache? cache;
  final BudgetRolloverRepository? rolloverRepository;
  final BudgetExpenseFilter? budgetFilter;
  final DateTime Function() _now;

  Future<List<String>> facts() async {
    final now = _now();
    final expenses = (await expenseRepository.getExpenses())
        .where((e) => !e.isDeleted)
        .toList();
    final limits = await budgetRepository.getLimits();
    final periods = await budgetRepository.getPeriods();
    final rollover = rolloverRepository;
    final budgetExpenses = budgetFilter?.forBudgets(expenses) ?? expenses;
    return WeeklyDigestBuilder.build(
      expenses: expenses,
      budgets: BudgetProgressCalculator.compute(
        expenses: budgetExpenses,
        limits: limits,
        periods: periods,
        now: now,
        carryOver: rollover == null
            ? const {}
            : RolloverCalculator.carryOver(
                limits: limits,
                periods: periods,
                settings: rollover.getAll(),
                expenses: budgetExpenses,
                now: now,
              ),
      ),
      upcomingBills: BillReminderPlanner.plan(
        await recurringRepository.getAll(),
        now: now,
      ),
      now: now,
    );
  }

  /// [allowModel] false returns the cached rewrite or the template without
  /// ever starting the model (used on the startup path).
  Future<WeeklyDigest> call({bool allowModel = true}) async {
    final lines = await facts();
    final key = lines.join('|');

    final cached = cache?.read();
    if (cached != null && cached.factsKey == key) {
      return WeeklyDigest(lines: cached.lines, aiWritten: true);
    }

    final w = writer;
    final recentlyWritten =
        cached != null &&
        _now().difference(cached.writtenAt) < minRewriteInterval;
    if (!allowModel || w == null || recentlyWritten) {
      return WeeklyDigest(lines: lines, aiWritten: false);
    }

    try {
      if (!await w.isAvailable()) {
        return WeeklyDigest(lines: lines, aiWritten: false);
      }
      final output = await w.rewrite(lines).timeout(rewriteTimeout);
      final accepted = DigestFaithfulness.accept(output, lines);
      if (accepted == null) return WeeklyDigest(lines: lines, aiWritten: false);

      await cache?.write(key, accepted, _now());
      return WeeklyDigest(lines: accepted, aiWritten: true);
    } catch (_) {
      return WeeklyDigest(lines: lines, aiWritten: false);
    }
  }
}
