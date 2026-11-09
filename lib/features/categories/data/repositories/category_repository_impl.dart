import 'package:hive/hive.dart';

import '../../../../core/constants/custom_category_registry.dart';
import '../../../../core/logging/app_log_buffer.dart';
import '../../domain/entities/custom_category.dart';
import '../../domain/repositories/category_repository.dart';
import '../datasources/category_remote_datasource.dart';

class CategoryRepositoryImpl implements CategoryRepository {
  CategoryRepositoryImpl({required this.box, required this.remote});

  /// Encrypted box of `id -> CustomCategory.toMap()`.
  final Box<dynamic> box;
  final CategoryRemoteDataSource remote;

  @override
  Future<void> initialize() async => _publish();

  @override
  List<CustomCategory> getAll() {
    return box.values
        .map(CustomCategory.fromMap)
        .whereType<CustomCategory>()
        .toList();
  }

  @override
  Future<void> save(CustomCategory category) async {
    await box.put(category.id, category.toMap());
    _publish();
    try {
      await remote.push(getAll());
    } catch (e, st) {
      // Stays local until the next successful push or pull.
      AppLogBuffer.instance.captureError('categories.push', e, st);
    }
  }

  @override
  Future<void> pullRemote() async {
    try {
      final remoteCategories = await remote.fetch();
      if (remoteCategories == null) return;

      var changed = false;
      for (final incoming in remoteCategories) {
        final local = CustomCategory.fromMap(box.get(incoming.id));
        if (local == null || incoming.updatedAt.isAfter(local.updatedAt)) {
          await box.put(incoming.id, incoming.toMap());
          changed = true;
        }
      }
      if (changed) _publish();

      // Push local-only or newer local entries back up.
      final remoteIds = {for (final c in remoteCategories) c.id: c};
      final needsPush = getAll().any((c) {
        final r = remoteIds[c.id];
        return r == null || c.updatedAt.isAfter(r.updatedAt);
      });
      if (needsPush) await remote.push(getAll());
    } catch (e, st) {
      AppLogBuffer.instance.captureError('categories.pull', e, st);
    }
  }

  @override
  Stream<void> watch() => box.watch().map((_) {});

  void _publish() => CustomCategoryRegistry.replaceAll(getAll());
}
