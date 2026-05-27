import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

import '../models/glasses.dart';

/// Vẽ kính lên canvas khi đã biết vị trí 2 mắt (trong KHÔNG GIAN của canvas đó).
///
/// Dùng chung cho:
///  - Live preview ([GlassesPainter]) sau khi đã đổi toạ độ ảnh → màn hình.
///  - Ảnh chụp ([ResultComposer]) vẽ thẳng trên pixel của ảnh.
///
/// [overlayImage]: nếu có (ảnh PNG kính tách nền do cửa hàng upload) thì dán ảnh;
/// nếu null thì vẽ gọng bằng vector theo shape + màu.
/// [headYaw]: góc xoay đầu trái/phải (độ) để tạo hiệu ứng 2.5D (kính co lại khi
/// quay mặt). Lấy từ Face.headEulerAngleY.
void drawGlassesAtEyes(
  Canvas canvas,
  Offset leftEye,
  Offset rightEye,
  Glasses glasses, {
  ui.Image? overlayImage,
  double headYaw = 0,
}) {
  final center = Offset((leftEye.dx + rightEye.dx) / 2,
      (leftEye.dy + rightEye.dy) / 2);
  final dx = rightEye.dx - leftEye.dx;
  final dy = rightEye.dy - leftEye.dy;
  final eyeDist = math.sqrt(dx * dx + dy * dy);
  if (eyeDist < 1) return;
  final angle = math.atan2(dy, dx);

  final glassesWidth = eyeDist * 2.3;
  final glassesHeight = glassesWidth * 0.42;

  // 2.5D: khi quay đầu, bề ngang kính co lại theo cos(yaw).
  final yawRad = headYaw * math.pi / 180.0;
  final scaleX = math.cos(yawRad).abs().clamp(0.45, 1.0);

  canvas.save();
  canvas.translate(center.dx, center.dy);
  canvas.rotate(angle);
  canvas.scale(scaleX, 1.0);

  if (overlayImage != null) {
    final src = Rect.fromLTWH(
        0, 0, overlayImage.width.toDouble(), overlayImage.height.toDouble());
    final dst = Rect.fromCenter(
        center: Offset.zero, width: glassesWidth, height: glassesHeight);
    canvas.drawImageRect(overlayImage, src, dst, Paint());
  } else {
    _drawVectorFrame(canvas, glassesWidth, glassesHeight, glasses);
  }
  canvas.restore();
}

void _drawVectorFrame(Canvas canvas, double w, double h, Glasses glasses) {
  final framePaint = Paint()
    ..color = glasses.frameColor
    ..style = PaintingStyle.stroke
    ..strokeWidth = math.max(2.0, w * 0.022)
    ..strokeCap = StrokeCap.round;
  final lensFill = Paint()
    ..color = Colors.white.withOpacity(0.10)
    ..style = PaintingStyle.fill;

  final lensW = w * 0.42;
  final lensH = h;
  final gap = w * 0.16;
  final leftCenter = Offset(-(gap / 2 + lensW / 2), 0);
  final rightCenter = Offset(gap / 2 + lensW / 2, 0);

  switch (glasses.shape) {
    case FrameShape.rectangle:
      _rounded(canvas, leftCenter, lensW, lensH, lensW * 0.18, framePaint,
          lensFill);
      _rounded(canvas, rightCenter, lensW, lensH, lensW * 0.18, framePaint,
          lensFill);
      break;
    case FrameShape.round:
      _oval(canvas, leftCenter, lensW, lensH * 1.05, framePaint, lensFill);
      _oval(canvas, rightCenter, lensW, lensH * 1.05, framePaint, lensFill);
      break;
    case FrameShape.catEye:
      _catEye(canvas, leftCenter, lensW, lensH, framePaint, lensFill,
          flip: false);
      _catEye(canvas, rightCenter, lensW, lensH, framePaint, lensFill,
          flip: true);
      break;
    case FrameShape.aviator:
      _aviator(canvas, leftCenter, lensW, lensH, framePaint, lensFill);
      _aviator(canvas, rightCenter, lensW, lensH, framePaint, lensFill);
      break;
  }

  canvas.drawLine(Offset(leftCenter.dx + lensW / 2, -h * 0.1),
      Offset(rightCenter.dx - lensW / 2, -h * 0.1), framePaint);
  canvas.drawLine(Offset(leftCenter.dx - lensW / 2, 0),
      Offset(leftCenter.dx - lensW / 2 - w * 0.12, -h * 0.15), framePaint);
  canvas.drawLine(Offset(rightCenter.dx + lensW / 2, 0),
      Offset(rightCenter.dx + lensW / 2 + w * 0.12, -h * 0.15), framePaint);
}

void _rounded(Canvas c, Offset center, double w, double h, double r,
    Paint stroke, Paint fill) {
  final rect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: center, width: w, height: h),
      Radius.circular(r));
  c.drawRRect(rect, fill);
  c.drawRRect(rect, stroke);
}

void _oval(Canvas c, Offset center, double w, double h, Paint stroke,
    Paint fill) {
  final rect = Rect.fromCenter(center: center, width: w, height: h);
  c.drawOval(rect, fill);
  c.drawOval(rect, stroke);
}

void _catEye(Canvas c, Offset center, double w, double h, Paint stroke,
    Paint fill,
    {required bool flip}) {
  final s = flip ? -1.0 : 1.0;
  final path = Path();
  final left = center.dx - w / 2;
  final right = center.dx + w / 2;
  final top = center.dy - h / 2;
  final bottom = center.dy + h / 2;
  final outerTopX = center.dx + s * (w / 2);
  path.moveTo(left, center.dy);
  path.quadraticBezierTo(center.dx, bottom, right, center.dy);
  path.quadraticBezierTo(
      outerTopX + s * w * 0.18, top - h * 0.25, center.dx, top);
  path.quadraticBezierTo(left, top, left, center.dy);
  c.drawPath(path, fill);
  c.drawPath(path, stroke);
}

void _aviator(Canvas c, Offset center, double w, double h, Paint stroke,
    Paint fill) {
  final path = Path();
  final left = center.dx - w / 2;
  final right = center.dx + w / 2;
  final top = center.dy - h / 2;
  final bottom = center.dy + h / 2;
  path.moveTo(left, top);
  path.lineTo(right, top);
  path.quadraticBezierTo(right, bottom, center.dx, bottom);
  path.quadraticBezierTo(left, bottom, left, top);
  c.drawPath(path, fill);
  c.drawPath(path, stroke);
}
