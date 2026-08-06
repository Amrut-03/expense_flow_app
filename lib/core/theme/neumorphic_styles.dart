import 'package:flutter/material.dart';
import 'app_colors.dart';

class NeuBox {
  static BoxDecoration raised(
    NeuPalette p, {
    double radius = 20,
    Color? bgColor,
  }) => BoxDecoration(
    color: bgColor ?? p.background,
    borderRadius: BorderRadius.circular(radius),
    boxShadow: [
      BoxShadow(
        color: p.shadowDarkLight,
        offset: const Offset(7, 7),
        blurRadius: 15,
      ),
      BoxShadow(
        color: p.shadowLight,
        offset: const Offset(-7, -7),
        blurRadius: 15,
      ),
    ],
  );

  static BoxDecoration inset(NeuPalette p, {double radius = 20}) =>
      BoxDecoration(
        color: p.background,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: p.shadowLight,
            offset: const Offset(4, 4),
            blurRadius: 8,
            spreadRadius: -2,
          ),
          BoxShadow(
            color: p.shadowDark,
            offset: const Offset(-4, -4),
            blurRadius: 8,
            spreadRadius: -2,
          ),
        ],
      );

  static BoxDecoration pressed(
    NeuPalette p, {
    double radius = 20,
    Color? bgColor,
  }) => BoxDecoration(
    color: bgColor ?? p.background,
    borderRadius: BorderRadius.circular(radius),
    boxShadow: [
      BoxShadow(
        color: p.shadowDark,
        offset: const Offset(-4, -4),
        blurRadius: 8,
        spreadRadius: -2,
      ),
      BoxShadow(
        color: p.shadowLight,
        offset: const Offset(4, 4),
        blurRadius: 8,
        spreadRadius: -2,
      ),
    ],
  );
}
