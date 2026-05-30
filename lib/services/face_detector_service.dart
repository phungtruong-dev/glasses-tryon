import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

/// Wraps Google ML Kit Face Detection for iOS/Android real-time camera frames.
/// Not used on macOS (Vision framework handles detection there).
class FaceDetectorService {
  // MLKit FaceDetector is only created on non-macOS platforms.
  FaceDetector? _detector;

  FaceDetectorService() {
    if (!Platform.isMacOS) {
      _detector = FaceDetector(
        options: FaceDetectorOptions(
          enableLandmarks: true,
          enableContours: false,
          enableClassification: false,
          enableTracking: true,
          performanceMode: FaceDetectorMode.fast,
        ),
      );
    }
  }

  static const _orientations = {
    DeviceOrientation.portraitUp: 0,
    DeviceOrientation.landscapeLeft: 90,
    DeviceOrientation.portraitDown: 180,
    DeviceOrientation.landscapeRight: 270,
  };

  Future<List<Face>> detect(InputImage image) =>
      _detector!.processImage(image);

  void dispose() => _detector?.close();

  /// Converts a camera frame to InputImage for MLKit. Returns null if the
  /// frame format is incompatible (caller should skip that frame).
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
