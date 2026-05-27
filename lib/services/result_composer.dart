import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

import '../models/glasses.dart';
import '../widgets/glasses_drawing.dart';
import 'capture_service.dart';

/// Ghép kính lên ảnh đã chụp ([ProcessedShot]) -> trả về ui.Image + file PNG.
class ResultComposer {
  static Future<({ui.Image image, File file})> compose(
    ProcessedShot shot,
    Glasses glasses, {
    ui.Image? overlayImage,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // Vẽ ảnh gốc.
    canvas.drawImage(shot.image, Offset.zero, Paint());

    // Vẽ kính lên từng mặt (toạ độ landmark cùng không gian pixel với ảnh).
    for (final face in shot.faces) {
      final l = face.landmarks[FaceLandmarkType.leftEye]?.position;
      final r = face.landmarks[FaceLandmarkType.rightEye]?.position;
      if (l == null || r == null) continue;
      drawGlassesAtEyes(
        canvas,
        Offset(l.x.toDouble(), l.y.toDouble()),
        Offset(r.x.toDouble(), r.y.toDouble()),
        glasses,
        overlayImage: overlayImage,
        headYaw: face.headEulerAngleY ?? 0,
      );
    }

    final picture = recorder.endRecording();
    final out = await picture.toImage(shot.width, shot.height);

    final bytes = await out.toByteData(format: ui.ImageByteFormat.png);
    final dir = await getTemporaryDirectory();
    final path =
        '${dir.path}/result_${DateTime.now().millisecondsSinceEpoch}.png';
    final file =
        await File(path).writeAsBytes(bytes!.buffer.asUint8List());

    return (image: out, file: file);
  }
}
