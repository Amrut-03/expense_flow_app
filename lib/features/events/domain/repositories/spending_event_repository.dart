import '../entities/spending_event.dart';

abstract interface class SpendingEventRepository {
  /// Synchronous read (local box); used on hot paths like budget maths.
  List<SpendingEvent> getAll();
  Future<void> save(SpendingEvent event);
  Future<void> delete(String id);
  Stream<void> watch();
}
