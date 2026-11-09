import 'package:equatable/equatable.dart';

/// A category the user created. Built-in categories are not stored.
class CustomCategory extends Equatable {
  final String id;
  final String label;
  final String emoji;

  /// ARGB colour value.
  final int colorValue;

  /// Archived categories disappear from pickers but keep labelling the
  /// expenses that already use them.
  final bool isArchived;
  final DateTime updatedAt;

  const CustomCategory({
    required this.id,
    required this.label,
    required this.emoji,
    required this.colorValue,
    this.isArchived = false,
    required this.updatedAt,
  });

  CustomCategory copyWith({
    String? label,
    String? emoji,
    int? colorValue,
    bool? isArchived,
    DateTime? updatedAt,
  }) {
    return CustomCategory(
      id: id,
      label: label ?? this.label,
      emoji: emoji ?? this.emoji,
      colorValue: colorValue ?? this.colorValue,
      isArchived: isArchived ?? this.isArchived,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'label': label,
    'emoji': emoji,
    'colorValue': colorValue,
    'isArchived': isArchived,
    'updatedAt': updatedAt.toIso8601String(),
  };

  static CustomCategory? fromMap(Object? raw) {
    if (raw is! Map) return null;
    final id = raw['id'];
    final label = raw['label'];
    if (id is! String || label is! String) return null;
    return CustomCategory(
      id: id,
      label: label,
      emoji: raw['emoji'] as String? ?? '🏷️',
      colorValue: (raw['colorValue'] as num?)?.toInt() ?? 0xFF607D8B,
      isArchived: raw['isArchived'] as bool? ?? false,
      updatedAt:
          DateTime.tryParse(raw['updatedAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  @override
  List<Object?> get props => [
    id,
    label,
    emoji,
    colorValue,
    isArchived,
    updatedAt,
  ];
}
