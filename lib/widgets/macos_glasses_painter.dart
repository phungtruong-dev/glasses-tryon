import 'dart:ui' as ui;
import 'package:flutter/material.dart';

import '../models/face_result.dart';
import '../models/glasses.dart';
import 'glasses_drawing.dart';

/// Paints glasses onto a Canvas for macOS where face coordinates come from
/// Apple Vision (image pixel space, top-left origin, unmirrored camera feed).
///
/// Since camera_macos displays a mirrored image (isVideoMirrored=true),
/// X coordinates are flipped before drawing so the overlay matches the display.
class MacOSGlassesPainter extends CustomPainter {
  final List<FaceResult> faces;
  final Size imageSize;
  final Glasses glasses;
  final ui.Image? overlayImage;

  const MacOSGlassesPainter({
    required this.faces,
    required this.imageSize,
    required this.glasses,
    this.overlayImage,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (imageSize.isEmpty || faces.isEmpty) return;
    final scaleX = size.width / imageSize.width;
    final scaleY = size.height / imageSize.height;

    for (final face in faces) {
      // Mirror X: Vision sees unmirrored frame, but the Texture is mirrored.
      final pL = Offset(
        size.width - face.leftEye.dx * scaleX,
        face.leftEye.dy * scaleY,
      );
      final pR = Offset(
        size.width - face.rightEye.dx * scaleX,
        face.rightEye.dy * scaleY,
      );
      drawGlassesAtEyes(
        canvas, pL, pR, glasses,
        overlayImage: overlayImage,
        headYaw: face.yaw,
        headPitch: face.pitch,
      );
    }
  }

  @override
  bool shouldRepaint(covariant MacOSGlassesPainter old) =>
      old.faces != faces ||
      old.glasses.id != glasses.id ||
      old.overlayImage != overlayImage ||
      old.imageSize != imageSize;
}
