import '../../../expense/domain/entities/expense_entity.dart';
import '../entities/envelope.dart';

/// Zero-based envelope maths, month by month from [EnvelopeSettings.startMonth].
///
/// Each envelope's leftover (or overspend) carries into next month, and
/// moves shift money between envelopes within a month. Allocations are the
/// current monthly budget limits (limit history isn't stored, so earlier
/// months are replayed with today's limits).
abstract final class EnvelopeCalculator {
  /// Months replayed at most, so a very old start can't make this slow.
  static const maxReplayMonths = 24;

  static EnvelopeMonth compute({
    required EnvelopeSettings settings,
    required Map<String, double> limits,
    required List<ExpenseEntity> expenses,
    required DateTime now,
  }) {
    final current = DateTime(now.year, now.month);
    var start = settings.startMonth == null
        ? current
        : DateTime(settings.startMonth!.year, settings.startMonth!.month);
    if (start.isAfter(current)) start = current;
    final earliest = DateTime(current.year, current.month - maxReplayMonths);
    if (start.isBefore(earliest)) start = earliest;

    final categories = {
      for (final e in limits.entries)
        if (e.value > 0) e.key,
      for (final m in settings.moves) ...[m.fromCategoryId, m.toCategoryId],
    };

    final spentByMonth = <String, Map<String, double>>{};
    for (final e in expenses) {
      if (e.isDeleted) continue;
      final key = EnvelopeSettings.monthKey(e.date);
      spentByMonth
          .putIfAbsent(key, () => {})
          .update(e.categoryId, (v) => v + e.amount, ifAbsent: () => e.amount);
    }

    var carried = {for (final c in categories) c: 0.0};
    List<EnvelopeBalance> balances = const [];
    for (
      var month = start;
      !month.isAfter(current);
      month = DateTime(month.year, month.month + 1)
    ) {
      final key = EnvelopeSettings.monthKey(month);
      final moved = {for (final c in categories) c: 0.0};
      for (final m in settings.moves) {
        if (EnvelopeSettings.monthKey(m.month) != key) continue;
        moved[m.fromCategoryId] = moved[m.fromCategoryId]! - m.amount;
        moved[m.toCategoryId] = moved[m.toCategoryId]! + m.amount;
      }
      final spent = spentByMonth[key] ?? const {};
      balances = [
        for (final c in categories)
          EnvelopeBalance(
            categoryId: c,
            assigned: limits[c] ?? 0,
            carried: carried[c]!,
            moved: moved[c]!,
            spent: spent[c] ?? 0,
          ),
      ];
      carried = {for (final b in balances) b.categoryId: b.available};
    }

    balances.sort((a, b) => b.assigned.compareTo(a.assigned));
    return EnvelopeMonth(
      month: current,
      income: settings.incomeFor(current),
      envelopes: balances,
    );
  }
}
