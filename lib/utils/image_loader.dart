import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;

import '../models/glasses.dart';

/// Nạp ảnh PNG kính (nếu có) thành ui.Image để dán lên mặt.
/// Trả null nếu kính không có overlay (sẽ vẽ vector).
Future<ui.Image?> loadOverlayImage(Glasses g) async {
  final src = g.overlayAsset;
  if (src == null) return null;
  try {
    final Uint8List bytes;
    if (src.startsWith('http')) {
      final res = await http.get(Uri.parse(src));
      if (res.statusCode != 200) return null;
      bytes = res.bodyBytes;
    } else {
      final data = await rootBundle.load(src);
      bytes = data.buffer.asUint8List();
    }
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    return frame.image;
  } catch (_) {
    return null;
  }
}
