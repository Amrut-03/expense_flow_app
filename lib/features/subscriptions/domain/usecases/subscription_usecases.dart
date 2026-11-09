import 'package:uuid/uuid.dart';

import '../../../categories/domain/services/category_suggester.dart';
import '../../../expense/domain/repositories/expense_repository.dart';
import '../../../recurring/domain/entities/recurring_expense_entity.dart';
import '../../../recurring/domain/repositories/recurring_expense_repository.dart';
import '../entities/detected_subscription.dart';
import '../services/subscription_detector.dart';

class DetectSubscriptionsUseCase {
  DetectSubscriptionsUseCase({
    required this.expenseRepository,
    required this.recurringRepository,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final ExpenseRepository expenseRepository;
  final RecurringExpenseRepository recurringRepository;
  final DateTime Function() _now;

  Future<List<DetectedSubscription>> call() async {
    final rules = await recurringRepository.getAll();
    final tracked = {
      for (final r in rules)
        if (r.isActive)
          CategorySuggester.normalize(r.merchant ?? r.title ?? ''),
    }..remove('');

    return SubscriptionDetector.detect(
      expenses: await expenseRepository.getExpenses(),
      now: _now(),
      trackedKeys: tracked,
    );
  }
}

/// Turns a detected subscription into a recurring rule that starts at its
/// next expected charge, so future charges are logged automatically and no
/// past charges are duplicated.
class TrackSubscriptionUseCase {
  TrackSubscriptionUseCase(
    this.repository, {
    DateTime Function()? now,
    String Function()? newId,
  }) : _now = now ?? DateTime.now,
       _newId = newId ?? const Uuid().v4;

  final RecurringExpenseRepository repository;
  final DateTime Function() _now;
  final String Function() _newId;

  Future<RecurringExpenseEntity> call(DetectedSubscription sub) async {
    final now = _now();
    final rule = RecurringExpenseEntity(
      id: _newId(),
      title: sub.name,
      merchant: sub.name,
      amount: sub.amount,
      currency: 'INR',
      originalAmount: sub.amount,
      exchangeRate: 1,
      categoryId: sub.categoryId,
      paymentMethod: sub.paymentMethod,
      frequency: sub.frequency,
      startDate: sub.nextExpected,
      generatedCount: 0,
      createdAt: now,
      updatedAt: now,
    );
    await repository.save(rule);
    return rule;
  }
}
