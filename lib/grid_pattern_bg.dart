// ignore_for_file: prefer_typing_uninitialized_variables

import 'package:flutter/material.dart';

class GridPatternBackground extends StatelessWidget {
  final Widget child;
  final color;

  const GridPatternBackground({super.key, required this.child, this.color});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: GridPainter(color: color),
      child: child,
    );
  }
}

class GridPainter extends CustomPainter {
  final color;

  const GridPainter({this.color});


  @override
  void paint(Canvas canvas, Size size) {
    const double cellSize = 20.0;
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = 0.2;

    for (double x = 0.0; x < size.width; x += cellSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    for (double y = 0.0; y < size.height; y += cellSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}
