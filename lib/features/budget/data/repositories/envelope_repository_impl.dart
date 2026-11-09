import 'package:hive/hive.dart';

import '../../domain/entities/envelope.dart';
import '../../domain/repositories/envelope_repository.dart';

/// Stored in the encrypted settings box. Local to the device.
class EnvelopeRepositoryImpl implements EnvelopeRepository {
  EnvelopeRepositoryImpl(this.box);

  final Box<dynamic> box;

  static const _enabled = 'envelope_enabled';
  static const _start = 'envelope_start';
  static const _income = 'envelope_income';
  static const _moves = 'envelope_moves';

  /// Moves older than this are dropped on write (beyond the replay window).
  static const _keepMonths = 26;

  @override
  EnvelopeSettings get() {
    final income = box.get(_income);
    final moves = box.get(_moves);
    return EnvelopeSettings(
      enabled: box.get(_enabled) == true,
      startMonth: DateTime.tryParse(box.get(_start) as String? ?? ''),
      incomeByMonth: income is Map
          ? {
              for (final e in income.entries)
                if (e.key is String && e.value is num)
                  e.key as String: (e.value as num).toDouble(),
            }
          : const {},
      moves: moves is List
          ? moves.map(EnvelopeMove.fromMap).whereType<EnvelopeMove>().toList()
          : const [],
    );
  }

  @override
  Future<void> setEnabled(bool enabled, {required DateTime now}) async {
    await box.put(_enabled, enabled);
    // Balances start fresh each time the mode is switched on.
    if (enabled) {
      await box.put(_start, DateTime(now.year, now.month).toIso8601String());
    }
  }

  @override
  Future<void> setIncome(DateTime month, double amount) {
    final all = {...get().incomeByMonth};
    all[EnvelopeSettings.monthKey(month)] = amount;
    return box.put(_income, all);
  }

  @override
  Future<void> addMove(EnvelopeMove move) {
    final cutoff = DateTime(move.month.year, move.month.month - _keepMonths);
    final moves = [
      for (final m in get().moves)
        if (!m.month.isBefore(cutoff)) m.toMap(),
      move.toMap(),
    ];
    return box.put(_moves, moves);
  }

  @override
  Stream<void> watch() =>
      box.watch().where((e) => '${e.key}'.startsWith('envelope_')).map((_) {});
}
