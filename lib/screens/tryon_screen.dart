import 'dart:io';
import 'dart:ui' as ui;
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

import '../main.dart';
import '../models/glasses.dart';
import '../services/capture_service.dart';
import '../services/face_detector_service.dart';
import '../utils/image_loader.dart';
import '../widgets/glasses_painter.dart';
import '../widgets/glasses_selector.dart';
import '../widgets/macos_ar_body.dart';
import 'result_screen.dart';

class TryOnScreen extends StatefulWidget {
  final Glasses initialGlasses;
  final List<Glasses>? catalog;
  const TryOnScreen({super.key, required this.initialGlasses, this.catalog});

  @override
  State<TryOnScreen> createState() => _TryOnScreenState();
}

class _TryOnScreenState extends State<TryOnScreen>
    with WidgetsBindingObserver {
  // Mobile (iOS/Android) only — null on macOS.
  CameraController? _controller;
  FaceDetectorService? _faceService;

  bool _initializing = true;
  bool _busy = false;
  String? _error;

  List<Face> _faces = [];
  Size _imageSize = Size.zero;
  InputImageRotation _rotation = InputImageRotation.rotation0deg;
  late CameraDescription _camera;

  late Glasses _selected;
  final _capture = CaptureService();
  ui.Image? _overlayImage;
  bool _capturing = false;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialGlasses;
    WidgetsBinding.instance.addObserver(this);
    _loadOverlay(_selected);
    _start();
  }

  Future<void> _loadOverlay(Glasses g) async {
    final img = await loadOverlayImage(g);
    if (mounted) setState(() => _overlayImage = img);
  }

  void _select(Glasses g) {
    setState(() {
      _selected = g;
      _overlayImage = null;
    });
    _loadOverlay(g);
  }

  Future<void> _onCapture() async {
    final c = _controller;
    if (c == null || _capturing) return;
    setState(() => _capturing = true);
    try {
      if (c.value.isStreamingImages) await c.stopImageStream();
      final file = await c.takePicture();
      final shot = await _capture.processPhoto(File(file.path));
      if (!mounted) return;
      await Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => ResultScreen(
          shot: shot,
          glasses: _selected,
          overlayImage: _overlayImage,
        ),
      ));
      if (mounted && c.value.isInitialized && !c.value.isStreamingImages) {
        await c.startImageStream(_processCameraImage);
      }
    } catch (e) {
      _showSnack('Lỗi chụp ảnh: $e');
    } finally {
      if (mounted) setState(() => _capturing = false);
    }
  }

  void _showSnack(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(m)));
  }

  Future<void> _start() async {
    // macOS uses MacOSArBody which manages its own camera lifecycle.
    if (Platform.isMacOS) {
      setState(() => _initializing = false);
      return;
    }

    if (cameras.isEmpty) {
      setState(() {
        _initializing = false;
        _error = 'Không tìm thấy camera trên thiết bị này.';
      });
      return;
    }

    _faceService = FaceDetectorService();
    _camera = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );

    final controller = CameraController(
      _camera,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: Platform.isAndroid
          ? ImageFormatGroup.nv21
          : ImageFormatGroup.bgra8888,
    );
    _controller = controller;

    try {
      await controller.initialize();
      await controller.startImageStream(_processCameraImage);
      if (!mounted) return;
      setState(() => _initializing = false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _initializing = false;
        _error = 'Không mở được camera: $e\n'
            '(Kiểm tra quyền Camera trong cài đặt máy.)';
      });
    }
  }

  Future<void> _processCameraImage(CameraImage image) async {
    if (_busy || _faceService == null) return;
    _busy = true;

    final inputImage = _faceService!.inputImageFromCameraImage(
      image,
      _camera,
      _controller?.value.deviceOrientation ?? DeviceOrientation.portraitUp,
    );
    if (inputImage == null) {
      _busy = false;
      return;
    }

    try {
      final faces = await _faceService!.detect(inputImage);
      if (mounted) {
        setState(() {
          _faces = faces;
          _imageSize = inputImage.metadata?.size ?? Size.zero;
          _rotation =
              inputImage.metadata?.rotation ?? InputImageRotation.rotation0deg;
        });
      }
    } catch (_) {
      // skip bad frame
    } finally {
      _busy = false;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final c = _controller;
    if (c == null || !c.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      c.stopImageStream();
    } else if (state == AppLifecycleState.resumed) {
      if (!c.value.isStreamingImages) {
        c.startImageStream(_processCameraImage);
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    _faceService?.dispose();
    _capture.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(_selected.name),
      ),
      // macOS: FAB lives inside MacOSArBody.
      floatingActionButtonLocation: (!Platform.isMacOS)
          ? FloatingActionButtonLocation.centerFloat
          : null,
      floatingActionButton:
          (Platform.isMacOS || _initializing || _error != null)
              ? null
              : Padding(
                  padding: const EdgeInsets.only(bottom: 104),
                  child: FloatingActionButton.large(
                    onPressed: _capturing ? null : _onCapture,
                    child: _capturing
                        ? const CircularProgressIndicator()
                        : const Icon(Icons.camera_alt),
                  ),
                ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    // macOS: delegate entirely to MacOSArBody.
    if (Platform.isMacOS) {
      return MacOSArBody(
        selected: _selected,
        catalog: widget.catalog,
        overlayImage: _overlayImage,
        onSelectGlasses: _select,
      );
    }

    if (_initializing) {
      return const Center(
          child: CircularProgressIndicator(color: Colors.white));
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(_error!,
              style: const TextStyle(color: Colors.white),
              textAlign: TextAlign.center),
        ),
      );
    }

    final controller = _controller!;
    final catalog = (widget.catalog != null && widget.catalog!.isNotEmpty)
        ? widget.catalog!
        : kDemoGlasses;

    return Stack(
      fit: StackFit.expand,
      children: [
        Center(
          child: CameraPreview(
            controller,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final canvasSize =
                    Size(constraints.maxWidth, constraints.maxHeight);
                if (_imageSize == Size.zero) return const SizedBox.expand();
                return CustomPaint(
                  size: canvasSize,
                  painter: GlassesPainter(
                    faces: _faces,
                    imageSize: _imageSize,
                    rotation: _rotation,
                    lens: _camera.lensDirection,
                    glasses: _selected,
                    overlayImage: _overlayImage,
                  ),
                );
              },
            ),
          ),
        ),
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
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: GlassesSelector(
            options: catalog,
            selectedId: _selected.id,
            onSelect: _select,
          ),
        ),
      ],
    );
  }
}
