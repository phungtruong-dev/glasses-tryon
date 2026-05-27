import 'dart:io';
import 'dart:ui' as ui;
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

/// Kết quả 1 lần chụp đã chuẩn hoá: ảnh dựng đứng + mặt đã detect.
/// QUAN TRỌNG: faces nằm trong KHÔNG GIAN pixel của [image] (đã bake orientation),
/// nên có thể vẽ thẳng lên ảnh theo tỉ lệ 1:1.
class ProcessedShot {
  final File pngFile; // ảnh upright (.png, không còn EXIF orientation)
  final ui.Image image; // bitmap để vẽ canvas
  final int width;
  final int height;
  final List<Face> faces;

  ProcessedShot({
    required this.pngFile,
    required this.image,
    required this.width,
    required this.height,
    required this.faces,
  });
}

class CaptureService {
  final FaceDetector _detector = FaceDetector(
    options: FaceDetectorOptions(
      enableLandmarks: true,
      performanceMode: FaceDetectorMode.accurate, // ảnh tĩnh -> ưu tiên chính xác
    ),
  );

  void dispose() => _detector.close();

  /// [rawPhoto] là file từ CameraController.takePicture().
  Future<ProcessedShot> processPhoto(File rawPhoto) async {
    final bytes = await rawPhoto.readAsBytes();

    // 1) Bake EXIF orientation -> ảnh dựng đứng, loại bỏ lệch xoay.
    var decoded = img.decodeImage(bytes);
    if (decoded == null) {
      throw Exception('Không đọc được ảnh chụp.');
    }
    decoded = img.bakeOrientation(decoded);

    // 2) Lưu PNG upright vào thư mục tạm.
    final dir = await getTemporaryDirectory();
    final path =
        '${dir.path}/shot_${DateTime.now().millisecondsSinceEpoch}.png';
    final pngBytes = img.encodePng(decoded);
    final pngFile = await File(path).writeAsBytes(pngBytes);

    // 3) Detect mặt trên ảnh upright.
    final faces =
        await _detector.processImage(InputImage.fromFilePath(pngFile.path));

    // 4) Decode sang ui.Image để vẽ.
    final codec = await ui.instantiateImageCodec(pngBytes);
    final frame = await codec.getNextFrame();
    final uiImage = frame.image;

    return ProcessedShot(
      pngFile: pngFile,
      image: uiImage,
      width: decoded.width,
      height: decoded.height,
      faces: faces,
    );
  }
}
