import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../theme/app_colors.dart';
import '../../features/categories/domain/entities/custom_category.dart';
import 'custom_category_registry.dart';

class ExpenseCategory {
  final String id;
  final String label;
  final String emoji;

  /// ARGB colour for user-created categories; built-ins use the palette.
  final int? colorValue;
  final bool isCustom;

  const ExpenseCategory({
    required this.id,
    required this.label,
    required this.emoji,
    this.colorValue,
    this.isCustom = false,
  });

  String labelOf(AppLocalizations l10n) {
    return isCustom ? label : ExpenseCategories.localizedLabel(l10n, id);
  }
}

class ExpenseCategories {
  /// Built-in categories plus the user's active custom categories, in
  /// picker order.
  static List<ExpenseCategory> get all => [
    ...builtIn,
    for (final c in CustomCategoryRegistry.active) _fromCustom(c),
  ];

  static bool isBuiltIn(String id) => builtIn.any((c) => c.id == id);

  static ExpenseCategory _fromCustom(CustomCategory c) => ExpenseCategory(
    id: c.id,
    label: c.label,
    emoji: c.emoji,
    colorValue: c.colorValue,
    isCustom: true,
  );

  static const List<ExpenseCategory> builtIn = [
    ExpenseCategory(id: 'food', label: 'Food', emoji: '🍔'),
    ExpenseCategory(id: 'bills', label: 'Bills', emoji: '💡'),
    ExpenseCategory(id: 'shopping', label: 'Shopping', emoji: '🛍️'),
    ExpenseCategory(id: 'transport', label: 'Transport', emoji: '🚋'),
    ExpenseCategory(id: 'entertainment', label: 'Entertainment', emoji: '🎬'),
    ExpenseCategory(id: 'health', label: 'Health', emoji: '🏥'),
    ExpenseCategory(id: 'travel', label: 'Travel', emoji: '✈️'),
    ExpenseCategory(id: 'education', label: 'Education', emoji: '📚'),
  ];

  /// Looks up any category, including archived custom ones (so historic
  /// expenses keep their label). Unknown ids map to "Other".
  static ExpenseCategory byId(String id) {
    for (final category in builtIn) {
      if (category.id == id) return category;
    }
    final custom = CustomCategoryRegistry.byId(id);
    if (custom != null) return _fromCustom(custom);
    return const ExpenseCategory(id: 'other', label: 'Other', emoji: '💸');
  }

  static String localizedLabel(AppLocalizations l10n, String categoryId) {
    switch (categoryId) {
      case 'food':
        return l10n.category_food;
      case 'bills':
        return l10n.category_bills;
      case 'shopping':
        return l10n.category_shopping;
      case 'transport':
        return l10n.category_transport;
      case 'entertainment':
        return l10n.category_entertainment;
      case 'health':
        return l10n.category_health;
      case 'travel':
        return l10n.category_travel;
      case 'education':
        return l10n.category_education;
      default:
        return CustomCategoryRegistry.byId(categoryId)?.label ??
            l10n.category_other;
    }
  }

  static Color colorFor(NeuPalette palette, String categoryId) {
    final index = builtIn.indexWhere((category) => category.id == categoryId);
    if (index >= 0 && index < palette.categoryColors.length) {
      return palette.categoryColors[index];
    }
    final custom = CustomCategoryRegistry.byId(categoryId);
    if (custom != null) return Color(custom.colorValue);
    return palette.textMuted;
  }
}
