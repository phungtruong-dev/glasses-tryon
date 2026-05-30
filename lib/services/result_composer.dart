import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import '../models/glasses.dart';
import '../widgets/glasses_drawing.dart';
import 'capture_service.dart';

/// Composites glasses onto a [ProcessedShot] and returns the result image+file.
class ResultComposer {
  static Future<({ui.Image image, File file})> compose(
    ProcessedShot shot,
    Glasses glasses, {
    ui.Image? overlayImage,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    canvas.drawImage(shot.image, Offset.zero, Paint());

    // FaceResult.leftEye / rightEye are already in pixel space of shot.image.
    for (final face in shot.faces) {
      drawGlassesAtEyes(
        canvas,
        face.leftEye,
        face.rightEye,
        glasses,
        overlayImage: overlayImage,
        headYaw: face.yaw,
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
