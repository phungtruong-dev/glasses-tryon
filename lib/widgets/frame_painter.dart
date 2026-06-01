import 'package:flutter/material.dart';
import '../models/glasses.dart';

// Renders a glasses frame as a vector shape.
// Mirrors the FrameSVG from the design prototype (viewBox 0 0 260 100).
class FramePainter extends CustomPainter {
  final FrameShape shape;
  final Color frameColor;
  final Color lensColor;
  final double lensOpacity;
  final bool temples;
  final double strokeWidth;

  const FramePainter({
    required this.shape,
    required this.frameColor,
    this.lensColor = const Color(0xFF8A98A6),
    this.lensOpacity = 0.22,
    this.temples = true,
    this.strokeWidth = 7,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / 260;
    final sy = size.height / 100;
    canvas.scale(sx, sy);

    final frame = Paint()
      ..color = frameColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;

    final fill = Paint()
      ..color = lensColor.withValues(alpha: lensOpacity)
      ..style = PaintingStyle.fill;

    if (temples) {
      _drawTemples(canvas, frame);
    }

    switch (shape) {
      case FrameShape.round:    _drawRound(canvas, frame, fill);
      case FrameShape.catEye:   _drawCatEye(canvas, frame, fill);
      case FrameShape.aviator:  _drawAviator(canvas, frame, fill);
      case FrameShape.browline: _drawBrowline(canvas, frame, fill);
      case FrameShape.geometric:_drawGeometric(canvas, frame, fill);
      case FrameShape.rectangle:_drawRectangle(canvas, frame, fill);
    }
  }

  void _drawTemples(Canvas canvas, Paint p) {
    canvas.drawPath(_cubicPath(34, 48, 25, 47, 14, 50, 6, 54), p);
    canvas.drawPath(_cubicPath(226, 48, 235, 47, 246, 50, 254, 54), p);
  }

  void _drawRound(Canvas canvas, Paint frame, Paint fill) {
    canvas.drawCircle(const Offset(74, 50), 40, fill);
    canvas.drawCircle(const Offset(186, 50), 40, fill);
    canvas.drawCircle(const Offset(74, 50), 40, frame);
    canvas.drawCircle(const Offset(186, 50), 40, frame);
    canvas.drawPath(_cubicPath(114, 46, 122, 41, 130, 41, 146, 46), frame);
  }

  void _drawCatEye(Canvas canvas, Paint frame, Paint fill) {
    final lp = Path()
      ..moveTo(36, 56)
      ..cubicTo(38, 26, 74, 26, 104, 38)
      ..cubicTo(116, 48, 115, 62, 98, 66)
      ..cubicTo(76, 71, 54, 68, 40, 65)
      ..cubicTo(27, 63, 28, 57, 36, 56)
      ..close();
    final rp = Path()
      ..moveTo(224, 56)
      ..cubicTo(222, 26, 186, 26, 156, 38)
      ..cubicTo(144, 48, 145, 62, 162, 66)
      ..cubicTo(184, 71, 206, 68, 220, 65)
      ..cubicTo(233, 63, 232, 57, 224, 56)
      ..close();
    canvas.drawPath(lp, fill);
    canvas.drawPath(rp, fill);
    canvas.drawPath(lp, frame);
    canvas.drawPath(rp, frame);
    canvas.drawPath(_cubicPath(112, 42, 120, 35, 140, 35, 148, 42), frame);
  }

  void _drawAviator(Canvas canvas, Paint frame, Paint fill) {
    final lp = Path()
      ..moveTo(34, 36)
      ..cubicTo(55, 28, 96, 32, 104, 40)
      ..cubicTo(112, 58, 100, 82, 74, 86)
      ..cubicTo(44, 88, 22, 72, 24, 52)
      ..cubicTo(24, 44, 28, 38, 34, 36)
      ..close();
    final rp = Path()
      ..moveTo(226, 36)
      ..cubicTo(205, 28, 164, 32, 156, 40)
      ..cubicTo(148, 58, 160, 82, 186, 86)
      ..cubicTo(216, 88, 238, 72, 236, 52)
      ..cubicTo(236, 44, 232, 38, 226, 36)
      ..close();
    canvas.drawPath(lp, fill);
    canvas.drawPath(rp, fill);
    canvas.drawPath(lp, frame);
    canvas.drawPath(rp, frame);
    canvas.drawPath(_cubicPath(104, 40, 117, 34, 143, 34, 156, 40), frame);
  }

  void _drawBrowline(Canvas canvas, Paint frame, Paint fill) {
    final browPaint = Paint()
      ..color = frameColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth * 2.1
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(_cubicPath(30, 38, 74, 22, 118, 34, 118, 34), browPaint);
    canvas.drawPath(_cubicPath(142, 34, 186, 22, 230, 38, 230, 38), browPaint);
    final lRect = RRect.fromRectAndRadius(const Rect.fromLTWH(34, 32, 80, 48), const Radius.circular(20));
    final rRect = RRect.fromRectAndRadius(const Rect.fromLTWH(146, 32, 80, 48), const Radius.circular(20));
    canvas.drawRRect(lRect, fill);
    canvas.drawRRect(rRect, fill);
    canvas.drawRRect(lRect, frame);
    canvas.drawRRect(rRect, frame);
    canvas.drawPath(_cubicPath(114, 44, 122, 37, 138, 37, 146, 44), frame);
  }

  void _drawGeometric(Canvas canvas, Paint frame, Paint fill) {
    final lp = Path()..moveTo(34, 38)..lineTo(108, 32)..lineTo(112, 64)..lineTo(44, 80)..close();
    final rp = Path()..moveTo(226, 38)..lineTo(152, 32)..lineTo(148, 64)..lineTo(216, 80)..close();
    canvas.drawPath(lp, fill);
    canvas.drawPath(rp, fill);
    canvas.drawPath(lp, frame);
    canvas.drawPath(rp, frame);
    canvas.drawPath(_cubicPath(112, 44, 121, 38, 139, 38, 148, 44), frame);
  }

  void _drawRectangle(Canvas canvas, Paint frame, Paint fill) {
    final lRect = RRect.fromRectAndRadius(const Rect.fromLTWH(32, 30, 84, 50), const Radius.circular(16));
    final rRect = RRect.fromRectAndRadius(const Rect.fromLTWH(144, 30, 84, 50), const Radius.circular(16));
    canvas.drawRRect(lRect, fill);
    canvas.drawRRect(rRect, fill);
    canvas.drawRRect(lRect, frame);
    canvas.drawRRect(rRect, frame);
    canvas.drawPath(_cubicPath(116, 42, 124, 36, 136, 36, 144, 42), frame);
  }

  Path _cubicPath(double x1, double y1, double cx1, double cy1, double cx2, double cy2, double x2, double y2) =>
      Path()..moveTo(x1, y1)..cubicTo(cx1, cy1, cx2, cy2, x2, y2);

  @override
  bool shouldRepaint(FramePainter old) =>
      old.shape != shape || old.frameColor != frameColor ||
      old.lensColor != lensColor || old.lensOpacity != lensOpacity;
}

// Convenience widget
class FrameWidget extends StatelessWidget {
  final FrameShape shape;
  final Color frameColor;
  final Color lensColor;
  final double lensOpacity;
  final bool temples;
  final double strokeWidth;
  final double? width;
  final double? height;

  const FrameWidget({
    super.key,
    required this.shape,
    required this.frameColor,
    this.lensColor = const Color(0xFF8A98A6),
    this.lensOpacity = 0.22,
    this.temples = true,
    this.strokeWidth = 7,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: AspectRatio(
        aspectRatio: 260 / 100,
        child: CustomPaint(
          painter: FramePainter(
            shape: shape, frameColor: frameColor, lensColor: lensColor,
            lensOpacity: lensOpacity, temples: temples, strokeWidth: strokeWidth,
          ),
        ),
      ),
    );
  }
}
