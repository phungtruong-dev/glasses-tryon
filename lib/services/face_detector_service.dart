import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

/// Bọc Google ML Kit Face Detection.
///
/// Phần khó nhất của AR real-time KHÔNG phải là detect mặt, mà là chuyển
/// [CameraImage] (định dạng raw theo từng nền tảng) sang [InputImage] đúng
/// xoay/format. Code dưới đây xử lý đúng cho Android (NV21) và iOS (BGRA8888).
class FaceDetectorService {
  final FaceDetector _detector = FaceDetector(
    options: FaceDetectorOptions(
      enableLandmarks: true, // lấy điểm mắt, mũi, tai...
      enableContours: false,
      enableClassification: false,
      enableTracking: true,
      performanceMode: FaceDetectorMode.fast, // ưu tiên tốc độ cho real-time
    ),
  );

  // Bảng bù xoay theo hướng thiết bị (Android).
  static const _orientations = {
    DeviceOrientation.portraitUp: 0,
    DeviceOrientation.landscapeLeft: 90,
    DeviceOrientation.portraitDown: 180,
    DeviceOrientation.landscapeRight: 270,
  };

  Future<List<Face>> detect(InputImage image) => _detector.processImage(image);

  void dispose() => _detector.close();

  /// Chuyển frame camera -> InputImage. Trả null nếu frame không hợp lệ
  /// (caller nên bỏ qua frame đó).
  InputImage? inputImageFromCameraImage(
    CameraImage image,
    CameraDescription camera,
    DeviceOrientation deviceOrientation,
  ) {
    final sensorOrientation = camera.sensorOrientation;

    InputImageRotation? rotation;
    if (Platform.isIOS) {
      rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
    } else {
      var compensation = _orientations[deviceOrientation];
      if (compensation == null) return null;
      if (camera.lensDirection == CameraLensDirection.front) {
        compensation = (sensorOrientation + compensation) % 360;
      } else {
        compensation = (sensorOrientation - compensation + 360) % 360;
      }
      rotation = InputImageRotationValue.fromRawValue(compensation);
    }
    if (rotation == null) return null;

    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null) return null;
    // Android: cần NV21 (set imageFormatGroup: ImageFormatGroup.nv21 ở controller)
    // iOS: cần BGRA8888
    if ((Platform.isAndroid && format != InputImageFormat.nv21) ||
        (Platform.isIOS && format != InputImageFormat.bgra8888)) {
      return null;
    }

    if (image.planes.isEmpty) return null;
    final plane = image.planes.first;

    return InputImage.fromBytes(
      bytes: plane.bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: plane.bytesPerRow,
      ),
    );
  }
}
