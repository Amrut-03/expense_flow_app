import 'package:uuid/uuid.dart';

import '../../../../core/constants/category_label.dart';
import '../entities/custom_category.dart';
import '../repositories/category_repository.dart';

abstract final class CustomCategoryRules {
  static const maxLabelLength = 24;
  static const maxActive = 24;
}

class CategoryValidationException implements Exception {
  const CategoryValidationException(this.reason);

  final CategoryValidationError reason;

  @override
  String toString() => 'CategoryValidationException(${reason.name})';
}

enum CategoryValidationError { emptyName, nameTooLong, duplicateName, tooMany }

class CreateCustomCategoryUseCase {
  CreateCustomCategoryUseCase(
    this.repository, {
    DateTime Function()? now,
    String Function()? newId,
  }) : _now = now ?? DateTime.now,
       _newId = newId ?? (() => 'c_${const Uuid().v4().substring(0, 8)}');

  final CategoryRepository repository;
  final DateTime Function() _now;
  final String Function() _newId;

  Future<CustomCategory> call({
    required String label,
    required String emoji,
    required int colorValue,
  }) async {
    final name = label.trim();
    _validateName(repository, name);

    final activeCount = repository.getAll().where((c) => !c.isArchived).length;
    if (activeCount >= CustomCategoryRules.maxActive) {
      throw const CategoryValidationException(CategoryValidationError.tooMany);
    }

    final category = CustomCategory(
      id: _newId(),
      label: name,
      emoji: emoji,
      colorValue: colorValue,
      updatedAt: _now(),
    );
    await repository.save(category);
    return category;
  }
}

class UpdateCustomCategoryUseCase {
  UpdateCustomCategoryUseCase(this.repository, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final CategoryRepository repository;
  final DateTime Function() _now;

  Future<void> call(
    CustomCategory category, {
    String? label,
    String? emoji,
    int? colorValue,
  }) async {
    final name = label?.trim();
    if (name != null) {
      _validateName(repository, name, exceptId: category.id);
    }
    await repository.save(
      category.copyWith(
        label: name,
        emoji: emoji,
        colorValue: colorValue,
        updatedAt: _now(),
      ),
    );
  }
}

/// Hides a category from pickers. Existing expenses keep their label.
class ArchiveCustomCategoryUseCase {
  ArchiveCustomCategoryUseCase(this.repository, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final CategoryRepository repository;
  final DateTime Function() _now;

  Future<void> call(CustomCategory category) {
    return repository.save(
      category.copyWith(isArchived: true, updatedAt: _now()),
    );
  }
}

void _validateName(
  CategoryRepository repository,
  String name, {
  String? exceptId,
}) {
  if (name.isEmpty) {
    throw const CategoryValidationException(CategoryValidationError.emptyName);
  }
  if (name.length > CustomCategoryRules.maxLabelLength) {
    throw const CategoryValidationException(
      CategoryValidationError.nameTooLong,
    );
  }

  final lower = name.toLowerCase();
  final clashesBuiltIn = CategoryLabels.byId.values.any(
    (l) => l.toLowerCase() == lower,
  );
  final clashesCustom = repository.getAll().any(
    (c) => !c.isArchived && c.id != exceptId && c.label.toLowerCase() == lower,
  );
  if (clashesBuiltIn || clashesCustom) {
    throw const CategoryValidationException(
      CategoryValidationError.duplicateName,
    );
  }
}
