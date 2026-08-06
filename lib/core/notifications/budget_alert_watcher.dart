import 'dart:async';

import 'package:hive/hive.dart';

import '../../core/constants/category_label.dart';
import '../../core/notifications/amount_formatter.dart';
import '../../core/notifications/budget_alert_evaluator.dart';
import '../../core/notifications/local_notification_service.dart';
import '../../core/notifications/notification_payload.dart';
import '../../features/budget/domain/repositories/budget_repository.dart';
import '../../features/expense/data/models/expense_model.dart';
import '../../features/notifications/domain/entities/notification_type.dart';
import '../../features/notifications/domain/repositories/notification_settings_repository.dart';

/// Fires the Tier 1 "budget 80%/100%" alert locally.
///
/// Watches the Hive expense box (the source of truth the app writes every
/// transaction to). On any add/update, it recomputes the current month's spend
/// for that category and shows a local notification when a new threshold is
/// crossed. Alerts are deduped per category + calendar month so a user is
/// never spammed — the same behaviour as the (removed) cloud function.
class BudgetAlertWatcher {
  static const int _flag80 = 1;
  static const int _flag100 = 2;

  final LocalNotificationService notifications;
  final Box<ExpenseModel> expenseBox;
  final BudgetRepository budgetRepository;
  final Box<dynamic> stateBox;
  final BudgetAlertEvaluator evaluator;
  final NotificationSettingsRepository settingsRepository;

  StreamSubscription<BoxEvent>? _subscription;

  BudgetAlertWatcher({
    required this.notifications,
    required this.expenseBox,
    required this.budgetRepository,
    required this.stateBox,
    required this.settingsRepository,
    this.evaluator = const BudgetAlertEvaluator(),
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

    final limits = await budgetRepository.getLimits();
    final limit = limits[categoryId] ?? 0;
    if (limit <= 0) return;

    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 1);

    var spent = 0.0;
    for (final expense in expenseBox.values) {
      if (expense.categoryId != categoryId ||
          expense.isDeleted ||
          !expense.date.isAfter(
            monthStart.subtract(const Duration(seconds: 1)),
          ) ||
          !expense.date.isBefore(monthEnd)) {
        continue;
      }
      spent += expense.amount;
    }

    final result = evaluator.evaluate(spent: spent, limit: limit);
    if (result.level == BudgetAlertLevel.none) return;

    final key = 'budget_${categoryId}_${now.year}${_two(now.month)}';
    final sentFlags = (stateBox.get(key) as int?) ?? 0;

    final label = CategoryLabels.labelOf(categoryId);
    final exceeded = result.level == BudgetAlertLevel.exceeded;

    String title;
    String body;
    int newFlag;

    if (exceeded) {
      if ((sentFlags & _flag100) != 0) return;
      title = '$label budget exceeded';
      body =
          'You have spent ${formatInr(result.spent)} of your ${formatInr(result.limit)} $label budget this month.';
      newFlag = _flag100 | _flag80;
    } else {
      if ((sentFlags & _flag80) != 0) return;
      title = '$label budget ${result.percent.round()}% used';
      body =
          'You have used ${result.percent.round()}% of your $label budget this month.';
      newFlag = _flag80;
    }

    final payload = NotificationPayload(
      type: NotificationType.budgetAlert,
      title: title,
      message: body,
      emoji: '🎯',
      categoryId: categoryId,
    );

    await notifications.show(
      id: key.hashCode & 0x7fffffff,
      title: title,
      body: body,
      channelId: NotificationChannels.budgetAlerts,
      payload: payload.encode(),
    );

    await stateBox.put(key, sentFlags | newFlag);
  }

  String _two(int value) => value.toString().padLeft(2, '0');
}
