import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

import '../models/glasses.dart';

/// Draws glasses onto [canvas] given the two eye positions in canvas space.
///
/// Used by both the live preview painters and the result composer.
/// [overlayImage]: if provided, blends the product PNG; otherwise draws vector.
/// [headYaw] / [headPitch]: Euler angles for 2.5D perspective compression.
void drawGlassesAtEyes(
  Canvas canvas,
  Offset leftEye,
  Offset rightEye,
  Glasses glasses, {
  ui.Image? overlayImage,
  double headYaw = 0,
  double headPitch = 0,
}) {
  final eyeCenter = Offset(
    (leftEye.dx + rightEye.dx) / 2,
    (leftEye.dy + rightEye.dy) / 2,
  );
  final dx = rightEye.dx - leftEye.dx;
  final dy = rightEye.dy - leftEye.dy;
  final eyeDist = math.sqrt(dx * dx + dy * dy);
  if (eyeDist < 1) return;
  final angle = math.atan2(dy, dx);

  final glassesWidth = eyeDist * 2.3;
  final glassesHeight = glassesWidth * 0.42;

  // Shift center slightly below eye midpoint: real frames sit on the nose,
  // so the optical center of each lens is at eye level while the bridge is above.
  final center = Offset(eyeCenter.dx, eyeCenter.dy + glassesHeight * 0.08);

  // 2.5D perspective: compress horizontally for yaw, vertically for pitch.
  final yawRad   = headYaw   * math.pi / 180.0;
  final pitchRad = headPitch * math.pi / 180.0;
  final scaleX = math.cos(yawRad).abs().clamp(0.45, 1.0);
  final scaleY = math.cos(pitchRad).abs().clamp(0.55, 1.0);

  canvas.save();
  canvas.translate(center.dx, center.dy);
  canvas.rotate(angle);
  canvas.scale(scaleX, scaleY);

  if (overlayImage != null) {
    final src = Rect.fromLTWH(
        0, 0, overlayImage.width.toDouble(), overlayImage.height.toDouble());
    final dst = Rect.fromCenter(
        center: Offset.zero, width: glassesWidth, height: glassesHeight);
    // BlendMode.multiply: white bg disappears, dark frame survives.
    canvas.drawImageRect(
        overlayImage, src, dst, Paint()..blendMode = BlendMode.multiply);
  } else {
    _drawVectorFrame(canvas, glassesWidth, glassesHeight, glasses);
  }
  canvas.restore();
}

void _drawVectorFrame(Canvas canvas, double w, double h, Glasses glasses) {
  final frameColor = glasses.frameColor;
  final strokeW = math.max(2.5, w * 0.026);

  final framePaint = Paint()
    ..color = frameColor
    ..style = PaintingStyle.stroke
    ..strokeWidth = strokeW
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  // Tinted lens fill: a lighter, semi-transparent version of the frame color.
  final lensFill = Paint()
    ..color = _lensColor(frameColor)
    ..style = PaintingStyle.fill;

  // Subtle white highlight to simulate glass reflection.
  final shinePaint = Paint()
    ..color = Colors.white.withValues(alpha: 0.42)
    ..style = PaintingStyle.stroke
    ..strokeWidth = math.max(1.0, w * 0.011)
    ..strokeCap = StrokeCap.round;

  final lensW = w * 0.42;
  final lensH = h;
  // Narrower gap → more realistic bridge width.
  final gap = w * 0.10;
  final leftCenter  = Offset(-(gap / 2 + lensW / 2), 0);
  final rightCenter = Offset( (gap / 2 + lensW / 2), 0);

  // ── Lenses ────────────────────────────────────────────────────────────────
  switch (glasses.shape) {
    case FrameShape.rectangle:
    case FrameShape.geometric:
      _rounded(canvas, leftCenter,  lensW, lensH, lensW * 0.18, framePaint, lensFill);
      _rounded(canvas, rightCenter, lensW, lensH, lensW * 0.18, framePaint, lensFill);
      break;
    case FrameShape.round:
      _oval(canvas, leftCenter,  lensW, lensH * 1.05, framePaint, lensFill);
      _oval(canvas, rightCenter, lensW, lensH * 1.05, framePaint, lensFill);
      break;
    case FrameShape.catEye:
      _catEye(canvas, leftCenter,  lensW, lensH, framePaint, lensFill, flip: false);
      _catEye(canvas, rightCenter, lensW, lensH, framePaint, lensFill, flip: true);
      break;
    case FrameShape.aviator:
      _aviator(canvas, leftCenter,  lensW, lensH, framePaint, lensFill);
      _aviator(canvas, rightCenter, lensW, lensH, framePaint, lensFill);
      break;
    case FrameShape.browline:
      _browline(canvas, leftCenter,  lensW, lensH, framePaint, lensFill, strokeW);
      _browline(canvas, rightCenter, lensW, lensH, framePaint, lensFill, strokeW);
      break;
  }

  // ── Nose bridge ───────────────────────────────────────────────────────────
  // Sits near the TOP of each lens (where a real nose bridge rests).
  final bridgeY = -lensH * 0.30;
  canvas.drawLine(
    Offset(leftCenter.dx  + lensW / 2, bridgeY),
    Offset(rightCenter.dx - lensW / 2, bridgeY),
    framePaint,
  );

  // ── Temples (arms) ────────────────────────────────────────────────────────
  // Extend from the outer-top corner of each lens, going mostly horizontal
  // with a very slight downward angle (toward the ear).
  final templeY    = bridgeY;
  final templeEndY = bridgeY + lensH * 0.06;
  canvas.drawLine(
    Offset(leftCenter.dx  - lensW / 2, templeY),
    Offset(leftCenter.dx  - lensW / 2 - w * 0.17, templeEndY),
    framePaint,
  );
  canvas.drawLine(
    Offset(rightCenter.dx + lensW / 2, templeY),
    Offset(rightCenter.dx + lensW / 2 + w * 0.17, templeEndY),
    framePaint,
  );

  // ── Lens shine ────────────────────────────────────────────────────────────
  _drawLensShine(canvas, leftCenter,  lensW, lensH, shinePaint);
  _drawLensShine(canvas, rightCenter, lensW, lensH, shinePaint);
}

// ── Helpers ──────────────────────────────────────────────────────────────────

/// Derives a tinted, semi-transparent lens fill from the frame color.
Color _lensColor(Color frame) {
  final hsl = HSLColor.fromColor(frame);
  return hsl
      .withLightness((hsl.lightness + 0.28).clamp(0.15, 0.78))
      .withSaturation((hsl.saturation * 0.65).clamp(0.0, 1.0))
      .toColor()
      .withValues(alpha: 0.28);
}

/// A subtle curved highlight near the top-left of a lens to simulate glass.
void _drawLensShine(Canvas canvas, Offset center, double w, double h, Paint paint) {
  final path = Path()
    ..moveTo(center.dx - w * 0.30, center.dy - h * 0.20)
    ..quadraticBezierTo(
      center.dx - w * 0.04, center.dy - h * 0.40,
      center.dx + w * 0.16, center.dy - h * 0.20,
    );
  canvas.drawPath(path, paint);
}

void _rounded(Canvas c, Offset center, double w, double h, double r,
    Paint stroke, Paint fill) {
  final rect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: center, width: w, height: h),
      Radius.circular(r));
  c.drawRRect(rect, fill);
  c.drawRRect(rect, stroke);
}

void _oval(Canvas c, Offset center, double w, double h,
    Paint stroke, Paint fill) {
  final rect = Rect.fromCenter(center: center, width: w, height: h);
  c.drawOval(rect, fill);
  c.drawOval(rect, stroke);
}

void _catEye(Canvas c, Offset center, double w, double h,
    Paint stroke, Paint fill, {required bool flip}) {
  final s = flip ? -1.0 : 1.0;
  final left   = center.dx - w / 2;
  final right  = center.dx + w / 2;
  final top    = center.dy - h / 2;
  final bottom = center.dy + h / 2;
  final outerTopX = center.dx + s * (w / 2);
  final path = Path();
  path.moveTo(left, center.dy);
  path.quadraticBezierTo(center.dx, bottom, right, center.dy);
  path.quadraticBezierTo(outerTopX + s * w * 0.18, top - h * 0.25, center.dx, top);
  path.quadraticBezierTo(left, top, left, center.dy);
  c.drawPath(path, fill);
  c.drawPath(path, stroke);
}

void _aviator(Canvas c, Offset center, double w, double h,
    Paint stroke, Paint fill) {
  final left   = center.dx - w / 2;
  final right  = center.dx + w / 2;
  final top    = center.dy - h / 2;
  final bottom = center.dy + h / 2;
  final path = Path();
  path.moveTo(left, top);
  path.lineTo(right, top);
  path.quadraticBezierTo(right, bottom, center.dx, bottom);
  path.quadraticBezierTo(left, bottom, left, top);
  c.drawPath(path, fill);
  c.drawPath(path, stroke);
}

void _browline(Canvas c, Offset center, double w, double h,
    Paint stroke, Paint fill, double strokeW) {
  // Lower half: thin rounded lens
  final lowerH = h * 0.65;
  final lowerCenter = Offset(center.dx, center.dy + h * 0.18);
  _rounded(c, lowerCenter, w, lowerH, w * 0.16, stroke, fill);

  // Upper brow bar: thick solid bar across the top
  final browPaint = Paint()
    ..color = stroke.color
    ..style = PaintingStyle.stroke
    ..strokeWidth = strokeW * 2.2
    ..strokeCap = StrokeCap.round;
  final browY = center.dy - h * 0.28;
  c.drawLine(
    Offset(center.dx - w / 2, browY),
    Offset(center.dx + w / 2, browY),
    browPaint,
  );
}
