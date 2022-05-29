import 'package:flutter/material.dart';
import 'dart:math' as math;
class BackgroundArc extends StatelessWidget {
  final double width;
  final double height;

  const BackgroundArc({Key? key, required this.width, required this.height}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: MyPainter(),
      size: Size(width, height),
    );
  }
}

class MyPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = Colors.white24;
    canvas.drawArc(Rect.fromLTWH(-size.width /2, 0.0, size.width , size.height * 2),
        math.pi * 1.5, math.pi, false, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}