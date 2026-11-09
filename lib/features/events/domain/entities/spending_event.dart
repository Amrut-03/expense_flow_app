import 'package:equatable/equatable.dart';

enum SpendingEventKind {
  festival('🪔'),
  wedding('💍'),
  trip('✈️'),
  other('🎉');

  const SpendingEventKind(this.defaultEmoji);

  final String defaultEmoji;

  static SpendingEventKind fromName(Object? name) => values.firstWhere(
    (k) => k.name == name,
    orElse: () => SpendingEventKind.other,
  );
}

/// A temporary budget for an occasion (Diwali, a wedding) or a trip, which
/// spans categories and has its own dates. Expenses join it through
/// `ExpenseEntity.eventId`.
class SpendingEvent extends Equatable {
  final String id;
  final String name;
  final String emoji;
  final SpendingEventKind kind;

  /// First and last day (inclusive, date-only).
  final DateTime startDate;
  final DateTime endDate;

  /// Budget in INR.
  final double budget;

  /// Categories this event is suggested for. Empty means every category.
  final Set<String> categoryIds;

  /// Trip currency (ISO 4217). While the trip is on, new expenses default
  /// to it. `null` for INR / non-trip events.
  final String? currency;

  /// When true, tagged expenses don't count against monthly category
  /// budgets (they have their own budget here). Defaults on for trips.
  final bool separateFromBudgets;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SpendingEvent({
    required this.id,
    required this.name,
    required this.emoji,
    required this.kind,
    required this.startDate,
    required this.endDate,
    required this.budget,
    this.categoryIds = const {},
    this.currency,
    this.separateFromBudgets = false,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isTrip => kind == SpendingEventKind.trip;

  /// Day after [endDate], i.e. the exclusive end.
  DateTime get endExclusive =>
      DateTime(endDate.year, endDate.month, endDate.day + 1);

  int get totalDays => endExclusive.difference(startDate).inDays;

  bool isActiveOn(DateTime when) =>
      !when.isBefore(startDate) && when.isBefore(endExclusive);

  bool isUpcomingOn(DateTime when) => when.isBefore(startDate);

  bool hasEndedBy(DateTime when) => !when.isBefore(endExclusive);

  bool coversCategory(String categoryId) =>
      categoryIds.isEmpty || categoryIds.contains(categoryId);

  SpendingEvent copyWith({
    String? name,
    String? emoji,
    SpendingEventKind? kind,
    DateTime? startDate,
    DateTime? endDate,
    double? budget,
    Set<String>? categoryIds,
    String? currency,
    bool clearCurrency = false,
    bool? separateFromBudgets,
    DateTime? updatedAt,
  }) => SpendingEvent(
    id: id,
    name: name ?? this.name,
    emoji: emoji ?? this.emoji,
    kind: kind ?? this.kind,
    startDate: startDate ?? this.startDate,
    endDate: endDate ?? this.endDate,
    budget: budget ?? this.budget,
    categoryIds: categoryIds ?? this.categoryIds,
    currency: clearCurrency ? null : (currency ?? this.currency),
    separateFromBudgets: separateFromBudgets ?? this.separateFromBudgets,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'emoji': emoji,
    'kind': kind.name,
    'startDate': startDate.toIso8601String(),
    'endDate': endDate.toIso8601String(),
    'budget': budget,
    'categoryIds': categoryIds.toList(),
    'currency': currency,
    'separateFromBudgets': separateFromBudgets,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  static SpendingEvent? fromMap(Object? raw) {
    if (raw is! Map) return null;
    final id = raw['id'];
    final name = raw['name'];
    final start = DateTime.tryParse(raw['startDate'] as String? ?? '');
    final end = DateTime.tryParse(raw['endDate'] as String? ?? '');
    final budget = (raw['budget'] as num?)?.toDouble();
    final createdAt = DateTime.tryParse(raw['createdAt'] as String? ?? '');
    if (id is! String || name is! String) return null;
    if (start == null || end == null || budget == null || createdAt == null) {
      return null;
    }
    final kind = SpendingEventKind.fromName(raw['kind']);
    final categories = raw['categoryIds'];
    return SpendingEvent(
      id: id,
      name: name,
      emoji: raw['emoji'] as String? ?? kind.defaultEmoji,
      kind: kind,
      startDate: start,
      endDate: end,
      budget: budget,
      categoryIds: categories is List
          ? categories.whereType<String>().toSet()
          : const {},
      currency: raw['currency'] as String?,
      separateFromBudgets: raw['separateFromBudgets'] as bool? ?? false,
      createdAt: createdAt,
      updatedAt:
          DateTime.tryParse(raw['updatedAt'] as String? ?? '') ?? createdAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    emoji,
    kind,
    startDate,
    endDate,
    budget,
    categoryIds,
    currency,
    separateFromBudgets,
    createdAt,
    updatedAt,
  ];
}
