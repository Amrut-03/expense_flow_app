import '../../features/categories/domain/entities/custom_category.dart';

/// In-memory view of the user's custom categories.
///
/// Category lookups happen synchronously all over the app (pickers, charts,
/// AI chunk text), so the categories repository keeps this registry in sync
/// with storage and every lookup reads from here. Framework-free so domain
/// code can use it.
abstract final class CustomCategoryRegistry {
  static Map<String, CustomCategory> _byId = const {};

  /// Replaces the registry contents. Called by the categories repository.
  static void replaceAll(Iterable<CustomCategory> categories) {
    _byId = {for (final c in categories) c.id: c};
  }

  /// Any custom category, including archived ones.
  static CustomCategory? byId(String id) => _byId[id];

  /// Custom categories shown in pickers, in creation order.
  static List<CustomCategory> get active =>
      _byId.values.where((c) => !c.isArchived).toList(growable: false);

  static List<CustomCategory> get all => _byId.values.toList(growable: false);
}
