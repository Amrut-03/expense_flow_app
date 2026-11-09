import 'package:expense_flow_app/features/events/domain/entities/spending_event.dart';
import 'package:expense_flow_app/features/events/domain/repositories/spending_event_repository.dart';
import 'package:expense_flow_app/features/events/domain/services/event_progress.dart';
import 'package:expense_flow_app/features/events/domain/services/separate_event_budget_filter.dart';
import 'package:expense_flow_app/features/events/domain/usecases/spending_event_usecases.dart';
import 'package:expense_flow_app/features/expense/data/models/expense_model.dart';
import 'package:expense_flow_app/features/expense/domain/entities/expense_entity.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/expense_factory.dart';
import '../../helpers/in_memory_expense_repository.dart';

class _MemoryEvents implements SpendingEventRepository {
  final Map<String, SpendingEvent> byId = {};

  @override
  List<SpendingEvent> getAll() => byId.values.toList();

  @override
  Future<void> save(SpendingEvent event) async => byId[event.id] = event;

  @override
  Future<void> delete(String id) async => byId.remove(id);

  @override
  Stream<void> watch() => const Stream.empty();
}

SpendingEvent _event({
  String id = 'diwali',
  SpendingEventKind kind = SpendingEventKind.festival,
  DateTime? start,
  DateTime? end,
  double budget = 10000,
  Set<String> categories = const {},
  String? currency,
  bool separate = false,
}) => SpendingEvent(
  id: id,
  name: id,
  emoji: kind.defaultEmoji,
  kind: kind,
  startDate: start ?? DateTime(2026, 11, 1),
  endDate: end ?? DateTime(2026, 11, 10),
  budget: budget,
  categoryIds: categories,
  currency: currency,
  separateFromBudgets: separate,
  createdAt: DateTime(2026, 10),
  updatedAt: DateTime(2026, 10),
);

ExpenseEntity _tagged(
  double inr,
  DateTime date, {
  String event = 'diwali',
  String category = 'shopping',
  String currency = 'INR',
  double? original,
}) => ExpenseEntity(
  id: 'x${date.microsecondsSinceEpoch}$inr',
  amount: inr,
  currency: currency,
  originalAmount: original,
  categoryId: category,
  eventId: event,
  date: date,
  createdAt: date,
  updatedAt: date,
);

void main() {
  group('EventProgress', () {
    test('sums only tagged, non-deleted expenses; projects pace', () {
      final event = _event();
      final expenses = [
        _tagged(3000, DateTime(2026, 11, 2)),
        _tagged(1000, DateTime(2026, 11, 3), category: 'food'),
        _tagged(500, DateTime(2026, 11, 3), event: 'other'),
        expenseOf(amount: 999, date: DateTime(2026, 11, 3)),
      ];
      // Nov 5: 5 of 10 days elapsed (inclusive), 6 days left incl. today.
      final p = EventProgress.compute(event, expenses, DateTime(2026, 11, 5));
      expect(p.status, EventStatus.active);
      expect(p.spent, 4000);
      expect(p.byCategory, {'shopping': 3000, 'food': 1000});
      expect(p.daysLeft, 6);
      expect(p.perDayLeft, 1000);
      expect(p.projectedTotal, 8000);
      expect(p.projectedOver, isFalse);
    });

    test('status upcoming / ended', () {
      final event = _event();
      expect(
        EventProgress.compute(event, const [], DateTime(2026, 10, 20)).status,
        EventStatus.upcoming,
      );
      final ended = EventProgress.compute(
        event,
        const [],
        DateTime(2026, 11, 11),
      );
      expect(ended.status, EventStatus.ended);
      expect(ended.daysLeft, 0);
    });

    test('trip totals in trip currency at the observed rate', () {
      final trip = _event(
        id: 'bkk',
        kind: SpendingEventKind.trip,
        currency: 'THB',
      );
      final p = EventProgress.compute(trip, [
        _tagged(
          2500,
          DateTime(2026, 11, 2),
          event: 'bkk',
          currency: 'THB',
          original: 1000,
        ),
        // Paid in INR (e.g. hotel booked from home).
        _tagged(5000, DateTime(2026, 11, 1), event: 'bkk'),
      ], DateTime(2026, 11, 3));
      expect(p.tripRate, 2.5);
      expect(p.spent, 7500);
      expect(p.spentInTripCurrency, 3000);
    });
  });

  group('EventMatcher', () {
    final now = DateTime(2026, 11, 5);
    test('prefers an active trip, then a matching active event', () {
      final festival = _event(categories: {'shopping'});
      final trip = _event(id: 'goa', kind: SpendingEventKind.trip);
      final past = _event(
        id: 'old',
        start: DateTime(2026, 1, 1),
        end: DateTime(2026, 1, 3),
      );
      expect(
        EventMatcher.suggest([festival, trip, past], when: now)?.id,
        'goa',
      );
      expect(
        EventMatcher.suggest(
          [festival, past],
          when: now,
          categoryId: 'shopping',
        )?.id,
        'diwali',
      );
      expect(
        EventMatcher.suggest([festival], when: now, categoryId: 'bills'),
        isNull,
      );
    });
  });

  group('SaveSpendingEventUseCase', () {
    late _MemoryEvents repo;
    late SaveSpendingEventUseCase save;
    setUp(() {
      repo = _MemoryEvents();
      save = SaveSpendingEventUseCase(
        repo,
        now: () => DateTime(2026, 10, 1),
        newId: () => 'new',
      );
    });

    Future<Object?> errorOf(Future<void> Function() run) async {
      try {
        await run();
        return null;
      } on EventValidationException catch (e) {
        return e.error;
      }
    }

    test('validates name, budget and dates', () async {
      Future<void> attempt({
        String name = 'Diwali',
        double budget = 100,
        DateTime? end,
      }) => save(
        name: name,
        emoji: '',
        kind: SpendingEventKind.festival,
        startDate: DateTime(2026, 11, 1),
        endDate: end ?? DateTime(2026, 11, 5),
        budget: budget,
      );
      expect(await errorOf(() => attempt(name: '  ')), EventValidationError.name);
      expect(await errorOf(() => attempt(budget: 0)), EventValidationError.budget);
      expect(
        await errorOf(() => attempt(end: DateTime(2026, 10, 30))),
        EventValidationError.dates,
      );
      expect(await errorOf(attempt), isNull);
    });

    test('trips default to separate budgets and keep a foreign currency',
        () async {
      final trip = await save(
        name: 'Bangkok',
        emoji: '',
        kind: SpendingEventKind.trip,
        startDate: DateTime(2026, 12, 1, 15),
        endDate: DateTime(2026, 12, 7),
        budget: 80000,
        currency: 'thb',
      );
      expect(trip.separateFromBudgets, isTrue);
      expect(trip.currency, 'THB');
      expect(trip.emoji, '✈️');
      expect(trip.startDate, DateTime(2026, 12, 1));

      final festival = await save(
        name: 'Holi',
        emoji: '🎨',
        kind: SpendingEventKind.festival,
        startDate: DateTime(2027, 3, 1),
        endDate: DateTime(2027, 3, 2),
        budget: 2000,
        currency: 'USD',
      );
      expect(festival.separateFromBudgets, isFalse);
      expect(festival.currency, isNull);
    });

    test('round-trips through toMap/fromMap', () {
      final e = _event(categories: {'food'}, currency: 'EUR', separate: true);
      expect(SpendingEvent.fromMap(e.toMap()), e);
      expect(SpendingEvent.fromMap({'id': 1}), isNull);
    });
  });

  test('separate events are kept out of budget maths', () {
    final repo = _MemoryEvents()
      ..byId['trip'] = _event(id: 'trip', separate: true)
      ..byId['diwali'] = _event();
    final filter = SeparateEventBudgetFilter(repo);
    final expenses = [
      _tagged(100, DateTime(2026, 11, 2), event: 'trip'),
      _tagged(200, DateTime(2026, 11, 2)),
      expenseOf(amount: 300, date: DateTime(2026, 11, 2)),
      _tagged(400, DateTime(2026, 11, 2), event: 'deleted'),
    ];
    expect(
      filter.forBudgets(expenses).map((e) => e.amount),
      [200, 300, 400],
    );
  });

  test('deleting an event untags its expenses', () async {
    final events = _MemoryEvents()..byId['diwali'] = _event();
    final expenses = InMemoryExpenseRepository();
    final tagged = _tagged(100, DateTime(2026, 11, 2));
    await expenses.addExpense(tagged);
    await DeleteSpendingEventUseCase(events, expenses)('diwali');
    expect(events.byId, isEmpty);
    final after = (await expenses.getExpenses()).single;
    expect(after.eventId, isNull);
    expect(after.syncStatus, SyncStatus.pending);
    expect(after.version, tagged.version + 1);
  });

  test('eventId survives the Hive model and sync JSON', () {
    final e = _tagged(100, DateTime(2026, 11, 2));
    final model = ExpenseModel.fromEntity(e);
    expect(model.toEntity().eventId, 'diwali');
    expect(ExpenseModel.fromJson(model.toJson()).eventId, 'diwali');
  });
}
