import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../main.dart';
import '../services/capture_service.dart';
import 'pd_screen.dart';

/// Chụp 1 ảnh chân dung rồi mở màn đo PD.
class CaptureForPdScreen extends StatefulWidget {
  const CaptureForPdScreen({super.key});

  @override
  State<CaptureForPdScreen> createState() => _CaptureForPdScreenState();
}

class _CaptureForPdScreenState extends State<CaptureForPdScreen> {
  CameraController? _controller;
  final _capture = CaptureService();
  bool _ready = false;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    if (cameras.isEmpty) {
      setState(() => _error = 'Không tìm thấy camera.');
      return;
    }
    final cam = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );
    final c = CameraController(cam, ResolutionPreset.high,
        enableAudio: false);
    _controller = c;
    try {
      await c.initialize();
      if (!mounted) return;
      setState(() => _ready = true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Không mở được camera: $e');
    }
  }

  Future<void> _shoot() async {
    final c = _controller;
    if (c == null || _busy) return;
    setState(() => _busy = true);
    try {
      final file = await c.takePicture();
      final shot = await _capture.processPhoto(File(file.path));
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
    _controller?.dispose();
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
          : !_ready
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.white))
              : Stack(
                  fit: StackFit.expand,
                  children: [
                    Center(child: CameraPreview(_controller!)),
                    const Positioned(
                      top: 16,
                      left: 16,
                      right: 16,
                      child: Text(
                        'Cầm sẵn 1 thẻ ngân hàng/CCCD ngang dưới mắt, '
                        'nhìn thẳng rồi chụp.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    Positioned(
                      bottom: 32,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: FloatingActionButton.large(
                          onPressed: _busy ? null : _shoot,
                          child: _busy
                              ? const CircularProgressIndicator()
                              : const Icon(Icons.camera),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}
