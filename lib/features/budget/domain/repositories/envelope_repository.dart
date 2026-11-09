import '../entities/envelope.dart';

abstract interface class EnvelopeRepository {
  EnvelopeSettings get();
  Future<void> setEnabled(bool enabled, {required DateTime now});
  Future<void> setIncome(DateTime month, double amount);
  Future<void> addMove(EnvelopeMove move);
  Stream<void> watch();
}
