import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class ConcaveDecoration extends Decoration {
  final ShapeBorder shape;
  final double depth;
  final List<Color> colors;
  final double opacity;

  const ConcaveDecoration({
    required this.shape,
    required this.depth,
    this.colors = const [Color(0xFF7B8182), Color(0xFFFFFFFF)],
    this.opacity = 1.0,
  }) : assert(colors.length == 2);

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) =>
      _ConcaveDecorationPainter(shape, depth, colors, opacity);

  @override
  EdgeInsetsGeometry get padding => shape.dimensions;

  @override
  Decoration? lerpFrom(Decoration? a, double t) {
    if (a == null) return this;
    if (a is ConcaveDecoration) {
      final curvedT = Curves.easeInOut.transform(t);
      return ConcaveDecoration(
        shape: ShapeBorder.lerp(a.shape, shape, curvedT) ?? shape,
        depth: ui.lerpDouble(a.depth, depth, curvedT) ?? depth,
        colors: [
          Color.lerp(a.colors[0], colors[0], curvedT) ?? colors[0],
          Color.lerp(a.colors[1], colors[1], curvedT) ?? colors[1],
        ],
        opacity: ui.lerpDouble(a.opacity, opacity, curvedT) ?? opacity,
      );
    }
    return super.lerpFrom(a, t);
  }
}

class _ConcaveDecorationPainter extends BoxPainter {
  ShapeBorder shape;
  double depth;
  List<Color> colors;
  double opacity;

  _ConcaveDecorationPainter(this.shape, this.depth, this.colors, this.opacity) {
    if (depth > 0) {
      colors = [colors[1], colors[0]];
    } else {
      depth = -depth;
    }
    colors = [
      colors[0].withValues(alpha: opacity),
      colors[1].withValues(alpha: opacity),
    ];
  }

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    final shapePath = shape.getOuterPath(offset & configuration.size!);
    final rect = shapePath.getBounds();

    final delta = 16 / rect.longestSide;
    final stops = [0.5 - delta, 0.5 + delta];

    final path = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(rect.inflate(depth * 2))
      ..addPath(shapePath, Offset.zero);
    canvas.save();
    canvas.clipPath(shapePath);

    final paint = Paint()
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, depth);
    final clipSize = rect.size.aspectRatio > 1
        ? Size(rect.width, rect.height / 2)
        : Size(rect.width / 2, rect.height);

    for (final alignment in [Alignment.topLeft, Alignment.bottomRight]) {
      final shaderRect = alignment.inscribe(
        Size.square(rect.longestSide),
        rect,
      );
      paint.shader = ui.Gradient.linear(
        shaderRect.topLeft,
        shaderRect.bottomRight,
        colors,
        stops,
      );

      canvas.save();
      canvas.clipRect(alignment.inscribe(clipSize, rect));
      canvas.drawPath(path, paint);
      canvas.restore();
    }
    canvas.restore();

    final size = configuration.size;
    if (size == null) return;

    shape.paint(canvas, offset & size);
  }
}
