import 'package:flutter/material.dart';

/// Platform-agnostic face detection result.
/// Eye positions are in pixel coordinates of the captured/processed image
/// (top-left origin).
class FaceResult {
  final Offset leftEye;
  final Offset rightEye;
  final double yaw;   // head yaw in degrees (left/right)
  final double pitch; // head pitch in degrees (up/down)

  const FaceResult({
    required this.leftEye,
    required this.rightEye,
    this.yaw = 0,
    this.pitch = 0,
  });
}
