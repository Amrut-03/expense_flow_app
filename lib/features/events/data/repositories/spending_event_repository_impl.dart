import 'package:hive/hive.dart';

import '../../domain/entities/spending_event.dart';
import '../../domain/repositories/spending_event_repository.dart';

/// Events live in an encrypted Hive box as `id -> SpendingEvent.toMap()`.
/// Local-only, like savings goals.
class SpendingEventRepositoryImpl implements SpendingEventRepository {
  SpendingEventRepositoryImpl(this.box);

  final Box<dynamic> box;

  @override
  List<SpendingEvent> getAll() =>
      box.values.map(SpendingEvent.fromMap).whereType<SpendingEvent>().toList();

  @override
  Future<void> save(SpendingEvent event) => box.put(event.id, event.toMap());

  @override
  Future<void> delete(String id) => box.delete(id);

  @override
  Stream<void> watch() => box.watch().map((_) {});
}
