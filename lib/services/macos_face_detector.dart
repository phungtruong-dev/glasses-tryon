import 'package:camera_macos/camera_macos.dart';
import 'package:flutter/services.dart';

import '../models/face_result.dart';

/// Dart wrapper around the "glasses_tryon/face_detector" MethodChannel,
/// which calls the native FaceDetectorPlugin (Apple Vision framework).
class MacOSFaceDetector {
  static const _channel = MethodChannel('glasses_tryon/face_detector');

  /// Detect faces in a raw ARGB frame from camera_macos image stream.
  Future<List<FaceResult>> detectFromImageData(CameraImageData data) async {
    try {
      final raw = await _channel.invokeMethod<List>('detectFromBytes', {
        'bytes': Uint8List.fromList(data.bytes),
        'width': data.width,
        'height': data.height,
        'bytesPerRow': data.bytesPerRow,
      });
      return _parse(raw);
    } catch (_) {
      return [];
    }
  }

  /// Detect faces in a saved image file (PNG/JPEG).
  Future<List<FaceResult>> detectFromFile(String path) async {
    try {
      final raw = await _channel.invokeMethod<List>('detectFromFile', path);
      return _parse(raw);
    } catch (_) {
      return [];
    }
  }

  List<FaceResult> _parse(List? raw) {
    if (raw == null) return [];
    return raw
        .whereType<List>()
        .where((e) => e.length >= 5)
        .map((e) => FaceResult(
              leftEye: Offset(
                  (e[0] as num).toDouble(), (e[1] as num).toDouble()),
              rightEye: Offset(
                  (e[2] as num).toDouble(), (e[3] as num).toDouble()),
              yaw: (e[4] as num).toDouble(),
            ))
        .toList();
  }
}
