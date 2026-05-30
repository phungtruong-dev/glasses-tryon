import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

import '../models/face_result.dart';
import 'macos_face_detector.dart';

/// Normalised result of a single capture: upright image + detected face data.
/// [faces] coordinates are in pixel space of [image] (top-left origin).
class ProcessedShot {
  final File pngFile;
  final ui.Image image;
  final int width;
  final int height;
  final List<FaceResult> faces;

  ProcessedShot({
    required this.pngFile,
    required this.image,
    required this.width,
    required this.height,
    required this.faces,
  });
}

class CaptureService {
  // MLKit detector: only created on iOS/Android.
  FaceDetector? _mlkitDetector;
  MacOSFaceDetector? _macosDetector;

  CaptureService() {
    if (Platform.isMacOS) {
      _macosDetector = MacOSFaceDetector();
    } else {
      _mlkitDetector = FaceDetector(
        options: FaceDetectorOptions(
          enableLandmarks: true,
          performanceMode: FaceDetectorMode.accurate,
        ),
      );
    }
  }

  void dispose() => _mlkitDetector?.close();

  /// Process a raw photo file: bake orientation, detect faces, return result.
  Future<ProcessedShot> processPhoto(File rawPhoto) async {
    final bytes = await rawPhoto.readAsBytes();

    var decoded = img.decodeImage(bytes);
    if (decoded == null) throw Exception('Không đọc được ảnh chụp.');
    decoded = img.bakeOrientation(decoded);

    final dir = await getTemporaryDirectory();
    final path =
        '${dir.path}/shot_${DateTime.now().millisecondsSinceEpoch}.png';
    final pngBytes = img.encodePng(decoded);
    final pngFile = await File(path).writeAsBytes(pngBytes);

    final faces = await _detectFaces(pngFile.path);

    final codec = await ui.instantiateImageCodec(pngBytes);
    final frame = await codec.getNextFrame();

    return ProcessedShot(
      pngFile: pngFile,
      image: frame.image,
      width: decoded.width,
      height: decoded.height,
      faces: faces,
    );
  }

  Future<List<FaceResult>> _detectFaces(String pngPath) async {
    if (Platform.isMacOS) {
      return _macosDetector!.detectFromFile(pngPath);
    }
    final mlkitFaces = await _mlkitDetector!
        .processImage(InputImage.fromFilePath(pngPath));
    return mlkitFaces
        .where((f) =>
            f.landmarks[FaceLandmarkType.leftEye] != null &&
            f.landmarks[FaceLandmarkType.rightEye] != null)
        .map((f) => FaceResult(
              leftEye: Offset(
                f.landmarks[FaceLandmarkType.leftEye]!.position.x.toDouble(),
                f.landmarks[FaceLandmarkType.leftEye]!.position.y.toDouble(),
              ),
              rightEye: Offset(
                f.landmarks[FaceLandmarkType.rightEye]!.position.x.toDouble(),
                f.landmarks[FaceLandmarkType.rightEye]!.position.y.toDouble(),
              ),
              yaw: f.headEulerAngleY ?? 0,
            ))
        .toList();
  }
}
