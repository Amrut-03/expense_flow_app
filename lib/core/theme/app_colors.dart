import 'package:flutter/material.dart';

class NeuPalette {
  final Color background;
  final Color accent;
  final Color onAccent;
  final Color shadowDark;
  final Color shadowDarkLight;
  final Color shadowLight;
  final Color textDark;
  final Color textMuted;
  final Color success;
  final Color danger;
  final List<Color> categoryColors;

  const NeuPalette({
    required this.background,
    required this.accent,
    required this.onAccent,
    required this.shadowDark,
    required this.shadowDarkLight,
    required this.shadowLight,
    required this.textDark,
    required this.textMuted,
    required this.success,
    required this.danger,
    required this.categoryColors,
  });

  static const light = NeuPalette(
    background: Color(0xFFE7ECF3),
    accent: Color(0xFFE8722C),
    onAccent: Color(0xFFFFFFFF),
    shadowDark: Color(0xFF7B8182),
    shadowDarkLight: Color(0xFFCCD4D4),
    shadowLight: Color(0xFFFFFFFF),
    textDark: Color(0xFF3A4353),
    textMuted: Color(0xFF8A93A3),
    success: Color(0xFF43A047),
    danger: Color(0xFFE05555),
    categoryColors: [
      Color(0xFFF57C00),
      Color(0xFFFFA000),
      Color(0xFFE53935),
      Color(0xFF43A047),
      Color(0xFF8E24AA),
      Color(0xFF00897B),
      Color(0xFF1E88E5),
      Color(0xFFD81B60),
    ],
  );

  static const dark = NeuPalette(
    background: Color(0xFF1E2228),
    accent: Color(0xFFE8722C),
    onAccent: Color(0xFFFFFFFF),
    shadowDark: Color(0xFF14171B),
    shadowDarkLight: Color(0xFF0F1114),
    shadowLight: Color(0xFF2A2F37),
    textDark: Color(0xFFECEFF3),
    textMuted: Color(0xFF9AA2B1),
    success: Color(0xFF81C784),
    danger: Color(0xFFE57373),
    categoryColors: [
      Color(0xFFFFB74D),
      Color(0xFFFFD54F),
      Color(0xFFEF9A9A),
      Color(0xFF81C784),
      Color(0xFFBA68C8),
      Color(0xFF4DB6AC),
      Color(0xFF64B5F6),
      Color(0xFFF06292),
    ],
  );
}
