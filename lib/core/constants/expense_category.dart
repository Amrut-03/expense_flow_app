import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../theme/app_colors.dart';

class ExpenseCategory {
  final String id;
  final String label;
  final String emoji;

  const ExpenseCategory({
    required this.id,
    required this.label,
    required this.emoji,
  });

  String labelOf(AppLocalizations l10n) {
    return ExpenseCategories.localizedLabel(l10n, id);
  }
}

class ExpenseCategories {
  static const List<ExpenseCategory> all = [
    ExpenseCategory(id: 'food', label: 'Food', emoji: '🍔'),
    ExpenseCategory(id: 'bills', label: 'Bills', emoji: '💡'),
    ExpenseCategory(id: 'shopping', label: 'Shopping', emoji: '🛍️'),
    ExpenseCategory(id: 'transport', label: 'Transport', emoji: '🚋'),
    ExpenseCategory(id: 'entertainment', label: 'Entertainment', emoji: '🎬'),
    ExpenseCategory(id: 'health', label: 'Health', emoji: '🏥'),
    ExpenseCategory(id: 'travel', label: 'Travel', emoji: '✈️'),
    ExpenseCategory(id: 'education', label: 'Education', emoji: '📚'),
  ];

  static ExpenseCategory byId(String id) {
    return all.firstWhere(
      (category) => category.id == id,
      orElse: () =>
          const ExpenseCategory(id: 'other', label: 'Other', emoji: '💸'),
    );
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
        return l10n.category_other;
    }
  }

  static Color colorFor(NeuPalette palette, String categoryId) {
    final index = all.indexWhere((category) => category.id == categoryId);
    if (index < 0) return palette.textMuted;
    return palette.categoryColors[index];
  }
}
