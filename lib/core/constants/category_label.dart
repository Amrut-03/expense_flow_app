/// Human-readable category labels shared across domain features.
///
/// Kept framework-free so it can be used from domain layers (for example the
/// AI chunk generators and their refreshers) without pulling in Flutter.
class CategoryLabels {
  static const Map<String, String> byId = {
    'food': 'Food',
    'bills': 'Bills',
    'shopping': 'Shopping',
    'transport': 'Transport',
    'entertainment': 'Entertainment',
    'health': 'Health',
    'travel': 'Travel',
    'education': 'Education',
    'other': 'Other',
  };

  /// Returns the display label for [categoryId], falling back to the raw id
  /// when the category is unknown.
  static String labelOf(String categoryId) {
    return byId[categoryId] ?? categoryId;
  }
}
