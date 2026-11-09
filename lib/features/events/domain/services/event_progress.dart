import 'dart:math' as math;

import 'package:equatable/equatable.dart';

import '../../../expense/domain/entities/expense_entity.dart';
import '../entities/spending_event.dart';

enum EventStatus { upcoming, active, ended }

/// Where an event's spending stands.
class EventProgress extends Equatable {
  final SpendingEvent event;
  final EventStatus status;

  /// Total spent (INR) on expenses tagged with this event.
  final double spent;

  /// For trips: total in the trip currency (expenses paid in it, plus INR
  /// expenses converted at their own rate where known). `null` otherwise.
  final double? spentInTripCurrency;

  /// INR per 1 unit of trip currency, averaged over tagged expenses paid in
  /// it. `null` until one exists.
  final double? tripRate;

  final Map<String, double> byCategory;
  final List<ExpenseEntity> expenses;

  /// Days left including today (0 once ended, total days if upcoming).
  final int daysLeft;

  /// Spending at the current daily rate projects to this by the end.
  final double? projectedTotal;

  const EventProgress({
    required this.event,
    required this.status,
    required this.spent,
    this.spentInTripCurrency,
    this.tripRate,
    required this.byCategory,
    required this.expenses,
    required this.daysLeft,
    this.projectedTotal,
  });

  double get remaining => event.budget - spent;
  double get fraction => event.budget <= 0 ? 0 : spent / event.budget;
  bool get isOver => spent > event.budget;

  /// Even spread of what's left over the remaining days.
  double get perDayLeft =>
      daysLeft <= 0 ? 0 : math.max(0, remaining) / daysLeft;

  bool get projectedOver =>
      projectedTotal != null && projectedTotal! > event.budget;

  /// Converts an INR amount to the trip currency using the observed rate.
  double? toTripCurrency(double inr) {
    final rate = tripRate;
    return rate == null || rate <= 0 ? null : inr / rate;
  }

  static EventProgress compute(
    SpendingEvent event,
    Iterable<ExpenseEntity> allExpenses,
    DateTime now,
  ) {
    final expenses =
        allExpenses.where((e) => !e.isDeleted && e.eventId == event.id).toList()
          ..sort((a, b) => b.date.compareTo(a.date));

    var spent = 0.0;
    final byCategory = <String, double>{};
    for (final e in expenses) {
      spent += e.amount;
      byCategory.update(
        e.categoryId,
        (v) => v + e.amount,
        ifAbsent: () => e.amount,
      );
    }

    final status = event.isUpcomingOn(now)
        ? EventStatus.upcoming
        : event.hasEndedBy(now)
        ? EventStatus.ended
        : EventStatus.active;

    final today = DateTime(now.year, now.month, now.day);
    final daysLeft = switch (status) {
      EventStatus.upcoming => event.totalDays,
      EventStatus.ended => 0,
      EventStatus.active => event.endExclusive.difference(today).inDays,
    };

    double? projected;
    if (status == EventStatus.active) {
      final elapsed = event.totalDays - daysLeft + 1;
      projected = spent / elapsed * event.totalDays;
    }

    double? tripRate;
    double? inTripCurrency;
    final code = event.currency;
    if (code != null && code.toUpperCase() != 'INR') {
      var paidInr = 0.0;
      var paidForeign = 0.0;
      for (final e in expenses) {
        if (e.currency.toUpperCase() == code.toUpperCase() &&
            e.originalAmount != null) {
          paidInr += e.amount;
          paidForeign += e.originalAmount!;
        }
      }
      if (paidForeign > 0) {
        tripRate = paidInr / paidForeign;
        inTripCurrency = spent / tripRate;
      }
    }

    return EventProgress(
      event: event,
      status: status,
      spent: spent,
      spentInTripCurrency: inTripCurrency,
      tripRate: tripRate,
      byCategory: byCategory,
      expenses: expenses,
      daysLeft: daysLeft,
      projectedTotal: projected,
    );
  }

  @override
  List<Object?> get props => [
    event,
    status,
    spent,
    spentInTripCurrency,
    tripRate,
    byCategory,
    expenses,
    daysLeft,
    projectedTotal,
  ];
}

abstract final class EventMatcher {
  /// The event a new expense on [when] in [categoryId] most likely belongs
  /// to: an active event covering the category, trips first (you're
  /// travelling, so everything is trip spend), then the most recently
  /// started.
  static SpendingEvent? suggest(
    Iterable<SpendingEvent> events, {
    required DateTime when,
    String? categoryId,
  }) {
    final candidates = events
        .where(
          (e) =>
              e.isActiveOn(when) &&
              (categoryId == null || e.coversCategory(categoryId)),
        )
        .toList();
    if (candidates.isEmpty) return null;
    candidates.sort((a, b) {
      if (a.isTrip != b.isTrip) return a.isTrip ? -1 : 1;
      return b.startDate.compareTo(a.startDate);
    });
    return candidates.first;
  }

  /// An active trip with a foreign currency, if any.
  static SpendingEvent? activeTrip(
    Iterable<SpendingEvent> events,
    DateTime when,
  ) {
    for (final e in events) {
      if (e.isTrip && e.currency != null && e.isActiveOn(when)) return e;
    }
    return null;
  }
}
