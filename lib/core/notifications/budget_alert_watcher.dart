import 'dart:async';

import 'package:intl/intl.dart';
import 'package:hive/hive.dart';

import '../../core/constants/category_label.dart';
import '../../core/notifications/amount_formatter.dart';
import '../../core/notifications/budget_alert_evaluator.dart';
import '../../core/notifications/local_notification_service.dart';
import '../../core/notifications/notification_payload.dart';
import '../../core/utils/summary_dates.dart';
import '../../features/budget/domain/entities/budget_entity.dart';
import '../../features/budget/domain/repositories/budget_repository.dart';
import '../../features/budget/domain/repositories/budget_rollover_repository.dart';
import '../../features/budget/domain/services/budget_expense_filter.dart';
import '../../features/budget/domain/services/budget_progress_calculator.dart';
import '../../features/budget/domain/usecases/envelope_usecases.dart';
import '../../features/budget/domain/services/rollover_calculator.dart';
import '../../features/expense/data/models/expense_model.dart';
import '../../features/notifications/domain/entities/notification_type.dart';
import '../../features/notifications/domain/repositories/notification_settings_repository.dart';

/// Fires budget alerts locally: an 80% heads-up, a 100% exceeded alert, and
/// a pace alert when spending is on course to run out before the period ends.
///
/// Watches the Hive expense box (the source of truth the app writes every
/// transaction to). On any add/update it recomputes that category's spend
/// for its budget period (month, quarter or year) and shows a notification
/// when a new threshold is crossed. Each alert fires at most once per
/// category per period.
class BudgetAlertWatcher {
  static const int _flag80 = 1;
  static const int _flag100 = 2;
  static const int _flagPace = 4;

  final LocalNotificationService notifications;
  final Box<ExpenseModel> expenseBox;
  final BudgetRepository budgetRepository;
  final Box<dynamic> stateBox;
  final BudgetAlertEvaluator evaluator;
  final NotificationSettingsRepository settingsRepository;

  /// When set, carry-forward budgets alert against limit + rolled-over
  /// amount, matching what the budget screen shows.
  final BudgetRolloverRepository? rolloverRepository;

  /// Excludes spending that has its own (event/trip) budget.
  final BudgetExpenseFilter? budgetFilter;

  /// In envelope mode, alerts use the envelope balance.
  final EnvelopeAdjustments? envelopes;
  final DateTime Function() clock;

  StreamSubscription<BoxEvent>? _subscription;

  BudgetAlertWatcher({
    required this.notifications,
    required this.expenseBox,
    required this.budgetRepository,
    required this.stateBox,
    required this.settingsRepository,
    this.rolloverRepository,
    this.budgetFilter,
    this.envelopes,
    this.evaluator = const BudgetAlertEvaluator(),
    this.clock = DateTime.now,
  });

  /// Starts listening for expense changes. Safe to call multiple times.
  void start() {
    if (_subscription != null) return;

    _subscription = expenseBox.watch().listen((event) {
      if (event.deleted) return;
      final expense = event.value;
      if (expense == null || expense.isDeleted) return;

      unawaited(_maybeAlert(expense.categoryId));
    });
  }

  void dispose() {
    _subscription?.cancel();
    _subscription = null;
  }

  Future<void> _maybeAlert(String categoryId) async {
    if (!settingsRepository.getSettings().budgetAlertsEnabled) return;

    final limit = (await budgetRepository.getLimits())[categoryId] ?? 0;
    if (limit <= 0) return;
    final period =
        (await budgetRepository.getPeriods())[categoryId] ??
        BudgetPeriod.monthly;

    final now = clock();
    final all = [for (final model in expenseBox.values) model.toEntity()];
    final expenses = budgetFilter?.forBudgets(all) ?? all;
    final rollover = rolloverRepository?.getAll()[categoryId];
    final envelopeAdjustments = envelopes?.enabled == true
        ? envelopes!.compute(
            limits: await budgetRepository.getLimits(),
            periods: await budgetRepository.getPeriods(),
            expenses: expenses,
            now: now,
          )
        : null;
    final carryOver = envelopeAdjustments != null
        ? {categoryId: envelopeAdjustments[categoryId] ?? 0.0}
        : rollover == null
        ? const <String, double>{}
        : RolloverCalculator.carryOver(
            limits: {categoryId: limit},
            periods: {categoryId: period},
            settings: {categoryId: rollover},
            expenses: expenses,
            now: now,
          );

    final progress = BudgetProgressCalculator.compute(
      expenses: [
        for (final e in expenses)
          if (e.categoryId == categoryId) e,
      ],
      limits: {categoryId: limit},
      periods: {categoryId: period},
      now: now,
      carryOver: carryOver,
    );
    if (progress.isEmpty) return;
    final budget = progress.single;

    // Keyed by period start so monthly keys stay compatible with the
    // `budget_<cat>_<yyyymm>` format used by earlier versions.
    final key =
        'budget_${categoryId}_${SummaryDates.yyyymm(budget.window.start).replaceAll('-', '')}';
    final sentFlags = (stateBox.get(key) as int?) ?? 0;

    final label = CategoryLabels.labelOf(categoryId);
    final periodWord = _periodWord(period);
    final result = evaluator.evaluate(spent: budget.spent, limit: budget.limit);

    String? title;
    String? body;
    var newFlags = 0;

    if (result.level == BudgetAlertLevel.exceeded) {
      if ((sentFlags & _flag100) == 0) {
        title = '$label budget exceeded';
        body =
            'You have spent ${formatInr(result.spent)} of your '
            '${formatInr(result.limit)} $label budget this $periodWord.';
        newFlags = _flag100 | _flag80 | _flagPace;
      }
    } else if (result.level == BudgetAlertLevel.threshold80) {
      if ((sentFlags & _flag80) == 0) {
        title = '$label budget ${result.percent.round()}% used';
        body =
            'You have used ${result.percent.round()}% of your $label '
            'budget this $periodWord.';
        newFlags = _flag80;
      }
    } else if (budget.status == BudgetPaceStatus.atRisk &&
        budget.projectedRunOutDate != null) {
      if ((sentFlags & _flagPace) == 0) {
        final date = DateFormat('MMM d').format(budget.projectedRunOutDate!);
        title = '$label budget may run out early';
        body =
            'At your current pace, your $label budget runs out around '
            '$date. ${formatInr(budget.dailyAllowance)}/day keeps you on track.';
        newFlags = _flagPace;
      }
    }

    if (title == null || body == null) return;

    final payload = NotificationPayload(
      type: NotificationType.budgetAlert,
      title: title,
      message: body,
      emoji: newFlags == _flagPace ? '⏳' : '🎯',
      categoryId: categoryId,
    );

    await notifications.show(
      id: (key + newFlags.toString()).hashCode & 0x7fffffff,
      title: title,
      body: body,
      channelId: NotificationChannels.budgetAlerts,
      payload: payload.encode(),
    );

    await stateBox.put(key, sentFlags | newFlags);
  }

  String _periodWord(BudgetPeriod period) => switch (period) {
    BudgetPeriod.quarterly => 'quarter',
    BudgetPeriod.yearly => 'year',
    _ => 'month',
  };
}
