import 'dart:io';
import 'dart:math' show Point;
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

/// Chuyển toạ độ từ không gian ảnh (InputImage đã xoay) sang không gian
/// canvas/preview hiển thị trên màn hình. Dựa trên cách làm chính thức trong
/// ví dụ của google_mlkit. Có xử lý mirror cho camera trước.
class CoordinateTranslator {
  static double translateX(
    double x,
    Size canvasSize,
    Size imageSize,
    InputImageRotation rotation,
    CameraLensDirection lens,
  ) {
    switch (rotation) {
      case InputImageRotation.rotation90deg:
        return x *
            canvasSize.width /
            (Platform.isIOS ? imageSize.width : imageSize.height);
      case InputImageRotation.rotation270deg:
        return canvasSize.width -
            x *
                canvasSize.width /
                (Platform.isIOS ? imageSize.width : imageSize.height);
      case InputImageRotation.rotation0deg:
      case InputImageRotation.rotation180deg:
        switch (lens) {
          case CameraLensDirection.front:
            return canvasSize.width - x * canvasSize.width / imageSize.width;
          default:
            return x * canvasSize.width / imageSize.width;
        }
    }
  }

  static double translateY(
    double y,
    Size canvasSize,
    Size imageSize,
    InputImageRotation rotation,
    CameraLensDirection lens,
  ) {
    switch (rotation) {
      case InputImageRotation.rotation90deg:
      case InputImageRotation.rotation270deg:
        return y *
            canvasSize.height /
            (Platform.isIOS ? imageSize.height : imageSize.width);
      case InputImageRotation.rotation0deg:
      case InputImageRotation.rotation180deg:
        return y * canvasSize.height / imageSize.height;
    }
  }

  static Offset translatePoint(
    Point<int> p,
    Size canvasSize,
    Size imageSize,
    InputImageRotation rotation,
    CameraLensDirection lens,
  ) {
    return Offset(
      translateX(
          p.x.toDouble(), canvasSize, imageSize, rotation, lens),
      translateY(
          p.y.toDouble(), canvasSize, imageSize, rotation, lens),
    );
  }
}
