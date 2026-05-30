import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:camera_macos/camera_macos.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import '../models/face_result.dart';
import '../models/glasses.dart';
import '../screens/result_screen.dart';
import '../services/capture_service.dart';
import '../services/macos_face_detector.dart';
import 'glasses_selector.dart';
import 'macos_glasses_painter.dart';

/// Full-screen camera + AR overlay body for macOS.
/// Manages camera_macos lifecycle, periodic Vision face detection, and capture.
class MacOSArBody extends StatefulWidget {
  final Glasses selected;
  final List<Glasses>? catalog;
  final ui.Image? overlayImage;
  final ValueChanged<Glasses> onSelectGlasses;

  const MacOSArBody({
    super.key,
    required this.selected,
    required this.overlayImage,
    required this.onSelectGlasses,
    this.catalog,
  });

  @override
  State<MacOSArBody> createState() => _MacOSArBodyState();
}

class _MacOSArBodyState extends State<MacOSArBody> {
  CameraMacOSController? _controller;
  final _detector = MacOSFaceDetector();
  final _capture = CaptureService();

  List<FaceResult> _faces = [];
  Size _imageSize = Size.zero;
  bool _busy = false;
  bool _capturing = false;

  CameraImageData? _latestFrame;
  Timer? _detectionTimer;

  void _onCameraInit(CameraMacOSController controller) {
    _controller = controller;
    controller.startImageStream(_onFrame);
    // Run Vision at ~4 fps; preview texture is always smooth.
    _detectionTimer = Timer.periodic(
      const Duration(milliseconds: 250),
      _runDetection,
    );
  }

  void _onFrame(CameraImageData? data) {
    _latestFrame = data;
  }

  Future<void> _runDetection(Timer _) async {
    final frame = _latestFrame;
    if (frame == null || _busy) return;
    _busy = true;
    _latestFrame = null;
    try {
      final faces = await _detector.detectFromImageData(frame);
      if (mounted) {
        setState(() {
          _faces = faces;
          _imageSize = Size(frame.width.toDouble(), frame.height.toDouble());
        });
      }
    } finally {
      _busy = false;
    }
  }

  Future<void> _onCapture() async {
    final c = _controller;
    if (c == null || _capturing) return;
    setState(() => _capturing = true);
    _detectionTimer?.cancel();

    try {
      final file = await c.takePicture();
      if (file?.bytes == null || !mounted) return;

      final dir = await getTemporaryDirectory();
      final path =
          '${dir.path}/macos_onCapture${DateTime.now().millisecondsSinceEpoch}.jpg';
      final tmpFile = await File(path).writeAsBytes(file!.bytes!);

      final shot = await _capture.processPhoto(tmpFile);
      if (!mounted) return;

      await Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => ResultScreen(
          shot: shot,
          glasses: widget.selected,
          overlayImage: widget.overlayImage,
        ),
      ));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Lỗi chụp ảnh: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _capturing = false);
        _detectionTimer = Timer.periodic(
          const Duration(milliseconds: 250),
          _runDetection,
        );
      }
    }
  }

  @override
  void dispose() {
    _detectionTimer?.cancel();
    _controller?.stopImageStream();
    _controller?.destroy();
    _capture.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final catalog = (widget.catalog != null && widget.catalog!.isNotEmpty)
        ? widget.catalog!
        : kDemoGlasses;

    return Stack(
      fit: StackFit.expand,
      children: [
        CameraMacOSView(
          cameraMode: CameraMacOSMode.photo,
          fit: BoxFit.cover,
          enableAudio: false,
          resolution: PictureResolution.high,
          pictureFormat: PictureFormat.jpg,
          onCameraInizialized: _onCameraInit,
          onCameraLoading: (err) => err != null
              ? Center(
                  child: Text('$err',
                      style: const TextStyle(color: Colors.white)))
              : const Center(
                  child: CircularProgressIndicator(color: Colors.white)),
        ),

        // Glasses overlay
        if (_imageSize != Size.zero)
          LayoutBuilder(builder: (ctx, c) {
            return CustomPaint(
              size: Size(c.maxWidth, c.maxHeight),
              painter: MacOSGlassesPainter(
                faces: _faces,
                imageSize: _imageSize,
                glasses: widget.selected,
                overlayImage: widget.overlayImage,
              ),
            );
          }),

        // Face detection status badge
        Positioned(
          top: 12,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _faces.isEmpty
                    ? 'Đưa khuôn mặt vào khung hình…'
                    : 'Đã nhận diện khuôn mặt ✓',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
        ),

        // Capture button
        Positioned(
          bottom: 104,
          left: 0,
          right: 0,
          child: Center(
            child: FloatingActionButton.large(
              onPressed: _capturing ? null : _onCapture,
              child: _capturing
                  ? const CircularProgressIndicator()
                  : const Icon(Icons.camera_alt),
            ),
          ),
        ),

        // Glasses selector strip
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: GlassesSelector(
            options: catalog,
            selectedId: widget.selected.id,
            onSelect: widget.onSelectGlasses,
          ),
        ),
      ],
    );
  }
}
