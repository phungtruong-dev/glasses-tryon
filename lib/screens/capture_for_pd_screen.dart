import 'dart:io';
import 'package:camera/camera.dart';
import 'package:camera_macos/camera_macos.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import '../main.dart';
import '../services/capture_service.dart';
import 'pd_measure_screen.dart';

/// Captures a portrait photo then opens PdScreen for pupillary-distance measurement.
/// Uses camera_macos on macOS, camera package on iOS/Android.
class CaptureForPdScreen extends StatefulWidget {
  const CaptureForPdScreen({super.key});

  @override
  State<CaptureForPdScreen> createState() => _CaptureForPdScreenState();
}

class _CaptureForPdScreenState extends State<CaptureForPdScreen> {
  // Mobile (iOS/Android)
  CameraController? _mobileController;
  // macOS
  CameraMacOSController? _macController;

  final _capture = CaptureService();
  bool _ready = false;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (!Platform.isMacOS) _initMobile();
  }

  Future<void> _initMobile() async {
    if (cameras.isEmpty) {
      setState(() => _error = 'Không tìm thấy camera.');
      return;
    }
    final cam = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );
    final c = CameraController(cam, ResolutionPreset.high, enableAudio: false);
    _mobileController = c;
    try {
      await c.initialize();
      if (!mounted) return;
      setState(() => _ready = true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Không mở được camera: $e');
    }
  }

  void _onMacCameraInit(CameraMacOSController controller) {
    _macController = controller;
    if (mounted) setState(() => _ready = true);
  }

  Future<void> _shoot() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      ProcessedShot shot;
      if (Platform.isMacOS) {
        final file = await _macController!.takePicture();
        if (file?.bytes == null) return;
        final dir = await getTemporaryDirectory();
        final path =
            '${dir.path}/pd_capture_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final tmpFile = await File(path).writeAsBytes(file!.bytes!);
        shot = await _capture.processPhoto(tmpFile);
      } else {
        final file = await _mobileController!.takePicture();
        shot = await _capture.processPhoto(File(file.path));
      }
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => PdScreen(shot: shot)),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = 'Lỗi chụp: $e';
      });
    }
  }

  @override
  void dispose() {
    _mobileController?.dispose();
    _macController?.stopImageStream();
    _macController?.destroy();
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
        title: const Text('Chụp để đo PD'),
      ),
      body: _error != null
          ? Center(
              child: Text(_error!,
                  style: const TextStyle(color: Colors.white)))
          : Platform.isMacOS
              ? _buildMacOS()
              : _buildMobile(),
    );
  }

  Widget _buildMacOS() {
    return Stack(
      fit: StackFit.expand,
      children: [
        CameraMacOSView(
          cameraMode: CameraMacOSMode.photo,
          fit: BoxFit.cover,
          enableAudio: false,
          resolution: PictureResolution.high,
          pictureFormat: PictureFormat.jpg,
          onCameraInizialized: _onMacCameraInit,
          onCameraLoading: (_) => const Center(
              child: CircularProgressIndicator(color: Colors.white)),
        ),
        _instructions(),
        _captureButton(),
      ],
    );
  }

  Widget _buildMobile() {
    if (!_ready) {
      return const Center(
          child: CircularProgressIndicator(color: Colors.white));
    }
    return Stack(
      fit: StackFit.expand,
      children: [
        Center(child: CameraPreview(_mobileController!)),
        _instructions(),
        _captureButton(),
      ],
    );
  }

  Widget _instructions() => const Positioned(
        top: 16,
        left: 16,
        right: 16,
        child: Text(
          'Cầm sẵn 1 thẻ ngân hàng/CCCD ngang dưới mắt, nhìn thẳng rồi chụp.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white),
        ),
      );

  Widget _captureButton() => Positioned(
        bottom: 32,
        left: 0,
        right: 0,
        child: Center(
          child: FloatingActionButton.large(
            onPressed: (_busy || (Platform.isMacOS && !_ready)) ? null : _shoot,
            child: _busy
                ? const CircularProgressIndicator()
                : const Icon(Icons.camera),
          ),
        ),
      );
}
