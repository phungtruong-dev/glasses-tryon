import 'dart:io';
import 'dart:ui' as ui;
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

import '../main.dart' show cameras, AppState;
import '../models/glasses.dart';
import '../services/capture_service.dart';
import '../services/face_detector_service.dart';
import '../theme/lumen_theme.dart';
import '../utils/image_loader.dart';
import '../widgets/frame_painter.dart';
import '../widgets/glasses_painter.dart';
import '../widgets/lumen_components.dart';
import '../widgets/macos_ar_body.dart';
import 'compare_screen.dart';
import 'face_shape_screen.dart';
import 'result_screen.dart';

class TryOnScreen extends StatefulWidget {
  final Glasses initialGlasses;
  final List<Glasses>? catalog;
  const TryOnScreen({super.key, required this.initialGlasses, this.catalog});

  @override
  State<TryOnScreen> createState() => _TryOnScreenState();
}

class _TryOnScreenState extends State<TryOnScreen> with WidgetsBindingObserver {
  CameraController? _camCtrl;
  FaceDetectorService? _faceService;

  bool _initializing = true;
  bool _busy = false;
  String? _error;

  List<Face> _faces = [];
  Size _imageSize = Size.zero;
  InputImageRotation _rotation = InputImageRotation.rotation0deg;
  late CameraDescription _camera;

  late Glasses _selected;
  String _colorId = '';
  final _capture = CaptureService();
  ui.Image? _overlayImage;
  bool _capturing = false;
  bool _macOSFaceDetected = false;

  final _macosArKey = GlobalKey<MacOSArBodyState>();

  List<Glasses> get _catalog => widget.catalog ?? kCatalog;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialGlasses;
    _colorId = _selected.colors.first;
    WidgetsBinding.instance.addObserver(this);
    _loadOverlay(_selected);
    _start();
  }

  Future<void> _loadOverlay(Glasses g) async {
    final img = await loadOverlayImage(g);
    if (mounted) setState(() => _overlayImage = img);
  }

  void _selectFrame(Glasses g) {
    setState(() { _selected = g; _colorId = g.colors.first; _overlayImage = null; });
    _loadOverlay(g);
  }

  void _selectColor(String id) {
    setState(() { _colorId = id; });
  }

  Future<void> _onCapture() async {
    if (_capturing) return;
    if (Platform.isMacOS) {
      await _macosArKey.currentState?.triggerCapture();
      return;
    }
    final c = _camCtrl;
    if (c == null) return;
    setState(() => _capturing = true);
    try {
      if (c.value.isStreamingImages) await c.stopImageStream();
      final file = await c.takePicture();
      final shot = await _capture.processPhoto(File(file.path));
      if (!mounted) return;
      await Navigator.push(context, MaterialPageRoute(
        builder: (_) => ResultScreen(shot: shot, glasses: _selected, overlayImage: _overlayImage)));
      if (mounted && c.value.isInitialized && !c.value.isStreamingImages) {
        await c.startImageStream(_processCameraImage);
      }
    } catch (e) {
      _snack('Capture error: $e');
    } finally {
      if (mounted) setState(() => _capturing = false);
    }
  }

  void _snack(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  Future<void> _start() async {
    if (Platform.isMacOS) { setState(() => _initializing = false); return; }
    if (cameras.isEmpty) {
      setState(() { _initializing = false; _error = 'No camera found on this device.'; }); return;
    }
    _faceService = FaceDetectorService();
    _camera = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.front, orElse: () => cameras.first);
    final controller = CameraController(_camera, ResolutionPreset.high, enableAudio: false,
      imageFormatGroup: Platform.isAndroid ? ImageFormatGroup.nv21 : ImageFormatGroup.bgra8888);
    _camCtrl = controller;
    try {
      await controller.initialize();
      await controller.startImageStream(_processCameraImage);
      if (mounted) setState(() => _initializing = false);
    } catch (e) {
      if (mounted) setState(() { _initializing = false; _error = 'Cannot open camera: $e'; });
    }
  }

  Future<void> _processCameraImage(CameraImage image) async {
    if (_busy || _faceService == null) return;
    _busy = true;
    final inputImage = _faceService!.inputImageFromCameraImage(image, _camera,
      _camCtrl?.value.deviceOrientation ?? DeviceOrientation.portraitUp);
    if (inputImage == null) { _busy = false; return; }
    try {
      final faces = await _faceService!.detect(inputImage);
      if (mounted) setState(() {
        _faces = faces;
        _imageSize = inputImage.metadata?.size ?? Size.zero;
        _rotation = inputImage.metadata?.rotation ?? InputImageRotation.rotation0deg;
      });
    } catch (_) {} finally { _busy = false; }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final c = _camCtrl;
    if (c == null || !c.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) c.stopImageStream();
    else if (state == AppLifecycleState.resumed && !c.value.isStreamingImages) c.startImageStream(_processCameraImage);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _camCtrl?.dispose();
    _faceService?.dispose();
    _capture.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppState.of(context);
    final isSaved = appState.saved.contains(_selected.id);
    final cw = kColorways[_colorId] ?? kColorways['obsidian']!;

    return ColoredBox(
      color: Colors.black,
      child: Stack(children: [
        // Camera / AR body
        _buildCameraBody(),
        // Top overlay: nav + face indicator
        SafeArea(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          // NavBar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            child: Row(children: [
              // Back only if pushed onto Navigator stack; as a tab it's a no-op
              if (Navigator.canPop(context))
                _GlassBtn(onTap: () => Navigator.pop(context), child: const Icon(Icons.chevron_left, size: 22, color: LC.onNoir))
              else
                const SizedBox(width: 48),
              const Spacer(),
              Column(children: [
                Text(_selected.name, style: LT.serif(21, color: LC.onNoir)),
                Text(_selected.formatPrice(), style: LT.sans(10.5, color: LC.onNoirSoft, w: FontWeight.w500)),
              ]),
              const Spacer(),
              _GlassBtn(
                onTap: () => appState.toggleSave(_selected.id),
                child: Icon(isSaved ? Icons.favorite : Icons.favorite_border,
                  size: 22, color: isSaved ? const Color(0xFFE8A0A0) : LC.onNoir)),
            ]),
          ),
          // Face detected pill
          if (!_initializing) Builder(builder: (ctx) {
            final faceFound = Platform.isMacOS ? _macOSFaceDetected : _faces.isNotEmpty;
            return Center(child: Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Container(width: 7, height: 7, decoration: BoxDecoration(
                  color: faceFound ? const Color(0xFF7CCB8E) : Colors.orange,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: faceFound ? const Color(0xFF7CCB8E) : Colors.orange, blurRadius: 8)],
                )),
                const SizedBox(width: 7),
                Text(faceFound ? 'Face detected · Đã nhận diện' : 'Searching… · Đang tìm',
                  style: LT.sans(11.5, w: FontWeight.w600, color: LC.onNoir)),
              ]),
            ));
          }),
        ])),
        // Bottom controls
        Positioned(left: 0, right: 0, bottom: 0, child: SafeArea(
          top: false,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black.withValues(alpha: 0.86)]),
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              // Color switcher
              Padding(
                padding: const EdgeInsets.only(top: 28, bottom: 14),
                child: Center(child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text(cw.name, style: LT.sans(11, w: FontWeight.w600, color: LC.onNoirSoft)),
                    const SizedBox(width: 12),
                    ColorDots(colors: _selected.colors, selected: _colorId, onSelect: _selectColor, size: 20),
                  ]),
                )),
              ),
              // Frame strip
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Row(children: _catalog.map((f) {
                  final on = f.id == _selected.id;
                  final frameCw = kColorways[on ? _colorId : f.colors.first] ?? kColorways['obsidian']!;
                  return GestureDetector(
                    onTap: () => _selectFrame(f),
                    child: Container(
                      width: 78, margin: const EdgeInsets.only(right: 10),
                      padding: const EdgeInsets.fromLTRB(6, 10, 6, 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: on ? LC.accent : Colors.white.withValues(alpha: 0.12), width: on ? 1.5 : 1),
                        color: Colors.white.withValues(alpha: 0.06),
                      ),
                      child: Column(children: [
                        FrameWidget(shape: f.shape, frameColor: on ? frameCw.hex : const Color(0xFFC9C2B4),
                          lensColor: const Color(0xFF8A98A6), temples: false),
                        const SizedBox(height: 5),
                        Text(f.name, style: LT.sans(9.5, w: FontWeight.w600,
                          color: on ? LC.accent : LC.onNoirSoft),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      ]),
                    ),
                  );
                }).toList()),
              ),
              // Capture row
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  _GlassBtn(onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CompareScreen())),
                    child: const Icon(Icons.compare_outlined, size: 22, color: LC.onNoir)),
                  const SizedBox(width: 38),
                  // Shutter
                  GestureDetector(
                    onTap: (!_initializing && _error == null) ? _onCapture : null,
                    child: Container(
                      width: 74, height: 74,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle, color: Colors.transparent,
                        border: Border.all(color: Colors.white.withValues(alpha: 0.9), width: 3),
                      ),
                      child: Center(child: AnimatedContainer(
                        duration: const Duration(milliseconds: 100),
                        width: _capturing ? 52 : 58, height: _capturing ? 52 : 58,
                        decoration: BoxDecoration(color: LC.paper, shape: BoxShape.circle),
                        child: _capturing ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: LC.ink)) : null,
                      )),
                    ),
                  ),
                  const SizedBox(width: 38),
                  _GlassBtn(onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FaceShapeScreen())),
                    child: const Icon(Icons.auto_awesome_outlined, size: 22, color: LC.onNoir)),
                ]),
              ),
            ]),
          ),
        )),
      ]),
    );
  }

  Widget _buildCameraBody() {
    if (Platform.isMacOS) {
      return MacOSArBody(
        key: _macosArKey,
        selected: _selected,
        catalog: widget.catalog,
        overlayImage: _overlayImage,
        onSelectGlasses: _selectFrame,
        onFaceDetected: (found) => setState(() => _macOSFaceDetected = found),
      );
    }
    if (_initializing) return const Center(child: CircularProgressIndicator(color: Colors.white));
    if (_error != null) return Center(child: Padding(padding: const EdgeInsets.all(24),
      child: Text(_error!, style: LT.sans(14, color: Colors.white), textAlign: TextAlign.center)));
    final ctrl = _camCtrl!;
    return CameraPreview(ctrl, child: LayoutBuilder(builder: (context, c) {
      if (_imageSize == Size.zero) return const SizedBox.expand();
      return CustomPaint(
        size: Size(c.maxWidth, c.maxHeight),
        painter: GlassesPainter(
          faces: _faces, imageSize: _imageSize, rotation: _rotation,
          lens: _camera.lensDirection, glasses: _selected, overlayImage: _overlayImage),
      );
    }));
  }
}

class _GlassBtn extends StatelessWidget {
  final VoidCallback onTap;
  final Widget child;
  const _GlassBtn({required this.onTap, required this.child});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 48, height: 48,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12), shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: child,
    ),
  );
}
