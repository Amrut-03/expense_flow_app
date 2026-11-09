import '../entities/custom_category.dart';

abstract class CategoryRepository {
  /// Loads stored categories into the in-memory registry.
  Future<void> initialize();

  /// All custom categories, including archived ones.
  List<CustomCategory> getAll();

  /// Inserts or replaces, then best-effort syncs to the cloud.
  Future<void> save(CustomCategory category);

  /// Merges the cloud copy into local storage (newest `updatedAt` wins).
  Future<void> pullRemote();

  Stream<void> watch();
}
