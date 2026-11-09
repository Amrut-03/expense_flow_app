import 'package:uuid/uuid.dart';

import '../../../expense/domain/entities/expense_entity.dart';
import '../../../expense/domain/repositories/expense_repository.dart';
import '../entities/spending_event.dart';
import '../repositories/spending_event_repository.dart';
import '../services/event_progress.dart';

enum EventValidationError { name, budget, dates }

class EventValidationException implements Exception {
  const EventValidationException(this.error);
  final EventValidationError error;
}

/// Creates or updates an event after validating it.
class SaveSpendingEventUseCase {
  SaveSpendingEventUseCase(
    this.repository, {
    DateTime Function()? now,
    String Function()? newId,
  }) : _now = now ?? DateTime.now,
       _newId = newId ?? const Uuid().v4;

  final SpendingEventRepository repository;
  final DateTime Function() _now;
  final String Function() _newId;

  static const maxNameLength = 40;

  Future<SpendingEvent> call({
    String? id,
    required String name,
    required String emoji,
    required SpendingEventKind kind,
    required DateTime startDate,
    required DateTime endDate,
    required double budget,
    Set<String> categoryIds = const {},
    String? currency,
    bool? separateFromBudgets,
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty || trimmed.length > maxNameLength) {
      throw const EventValidationException(EventValidationError.name);
    }
    if (!budget.isFinite || budget <= 0) {
      throw const EventValidationException(EventValidationError.budget);
    }
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day);
    if (end.isBefore(start) || end.difference(start).inDays > 366) {
      throw const EventValidationException(EventValidationError.dates);
    }

    final now = _now();
    final existing = id == null
        ? null
        : repository.getAll().where((e) => e.id == id).firstOrNull;
    final code = currency?.toUpperCase();
    final event = SpendingEvent(
      id: existing?.id ?? _newId(),
      name: trimmed,
      emoji: emoji.trim().isEmpty ? kind.defaultEmoji : emoji.trim(),
      kind: kind,
      startDate: start,
      endDate: end,
      budget: budget,
      categoryIds: categoryIds,
      currency: kind == SpendingEventKind.trip && code != 'INR' ? code : null,
      separateFromBudgets:
          separateFromBudgets ?? kind == SpendingEventKind.trip,
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
    );
    await repository.save(event);
    return event;
  }
}

/// Deletes an event and untags its expenses (they count against monthly
/// budgets again).
class DeleteSpendingEventUseCase {
  DeleteSpendingEventUseCase(this.repository, this.expenseRepository);

  final SpendingEventRepository repository;
  final ExpenseRepository expenseRepository;

  Future<void> call(String id) async {
    final tagged = (await expenseRepository.getExpenses()).where(
      (e) => e.eventId == id,
    );
    for (final e in tagged) {
      await expenseRepository.updateExpense(
        e.copyWith(
          clearEventId: true,
          updatedAt: DateTime.now(),
          version: e.version + 1,
          syncStatus: SyncStatus.pending,
        ),
      );
    }
    await repository.delete(id);
  }
}

/// Progress for every event: active first, then upcoming, then ended.
class GetEventProgressUseCase {
  GetEventProgressUseCase(
    this.repository,
    this.expenseRepository, {
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final SpendingEventRepository repository;
  final ExpenseRepository expenseRepository;
  final DateTime Function() _now;

  Future<List<EventProgress>> call() async {
    final now = _now();
    final expenses = await expenseRepository.getExpenses();
    final rank = {
      EventStatus.active: 0,
      EventStatus.upcoming: 1,
      EventStatus.ended: 2,
    };
    return [
      for (final e in repository.getAll())
        EventProgress.compute(e, expenses, now),
    ]..sort((a, b) {
      final byStatus = rank[a.status]!.compareTo(rank[b.status]!);
      if (byStatus != 0) return byStatus;
      return a.status == EventStatus.ended
          ? b.event.endDate.compareTo(a.event.endDate)
          : a.event.startDate.compareTo(b.event.startDate);
    });
  }
}
