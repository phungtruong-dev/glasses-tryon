import 'dart:ui' as ui;
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

import '../models/glasses.dart';
import '../utils/coordinate_translator.dart';
import 'glasses_drawing.dart';

/// Vẽ kính lên các khuôn mặt detect được trên live preview.
/// Toạ độ mắt được đổi từ không gian ảnh sang canvas (có xử lý mirror camera
/// trước), rồi gọi [drawGlassesAtEyes] dùng chung với phần chụp ảnh.
class GlassesPainter extends CustomPainter {
  final List<Face> faces;
  final Size imageSize;
  final InputImageRotation rotation;
  final CameraLensDirection lens;
  final Glasses glasses;

  /// Ảnh PNG kính tách nền (nếu cửa hàng cung cấp). Null -> vẽ vector.
  final ui.Image? overlayImage;

  GlassesPainter({
    required this.faces,
    required this.imageSize,
    required this.rotation,
    required this.lens,
    required this.glasses,
    this.overlayImage,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final face in faces) {
      final l = face.landmarks[FaceLandmarkType.leftEye]?.position;
      final r = face.landmarks[FaceLandmarkType.rightEye]?.position;
      if (l == null || r == null) continue;

      final pL = CoordinateTranslator.translatePoint(
          l, size, imageSize, rotation, lens);
      final pR = CoordinateTranslator.translatePoint(
          r, size, imageSize, rotation, lens);

      drawGlassesAtEyes(
        canvas,
        pL,
        pR,
        glasses,
        overlayImage: overlayImage,
        headYaw: face.headEulerAngleY ?? 0,
        headPitch: face.headEulerAngleX ?? 0,
      );
    }
  }

  @override
  bool shouldRepaint(covariant GlassesPainter old) =>
      old.faces != faces ||
      old.glasses.id != glasses.id ||
      old.overlayImage != overlayImage;
}
