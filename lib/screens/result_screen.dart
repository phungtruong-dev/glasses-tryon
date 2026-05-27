import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:share_plus/share_plus.dart';

import '../models/glasses.dart';
import '../services/capture_service.dart';
import '../services/result_composer.dart';
import 'pd_screen.dart';

class ResultScreen extends StatefulWidget {
  final ProcessedShot shot;
  final Glasses glasses;
  final ui.Image? overlayImage;

  const ResultScreen({
    super.key,
    required this.shot,
    required this.glasses,
    this.overlayImage,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  File? _resultFile;
  bool _working = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _compose();
  }

  Future<void> _compose() async {
    try {
      final r = await ResultComposer.compose(
        widget.shot,
        widget.glasses,
        overlayImage: widget.overlayImage,
      );
      if (!mounted) return;
      setState(() {
        _resultFile = r.file;
        _working = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Lỗi ghép ảnh: $e';
        _working = false;
      });
    }
  }

  Future<void> _save() async {
    if (_resultFile == null) return;
    try {
      await Gal.putImage(_resultFile!.path);
      _toast('Đã lưu vào thư viện ảnh ✓');
    } catch (e) {
      _toast('Không lưu được: $e');
    }
  }

  Future<void> _share() async {
    if (_resultFile == null) return;
    await Share.shareXFiles([XFile(_resultFile!.path)],
        text: 'Mình vừa thử mẫu kính "${widget.glasses.name}" 👓');
  }

  void _toast(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(m)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Kết quả thử kính'),
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: _working
                  ? const CircularProgressIndicator(color: Colors.white)
                  : _error != null
                      ? Text(_error!,
                          style: const TextStyle(color: Colors.white))
                      : Image.file(_resultFile!),
            ),
          ),
          if (!_working && _error == null)
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _save,
                        icon: const Icon(Icons.download),
                        label: const Text('Lưu'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _share,
                        icon: const Icon(Icons.share),
                        label: const Text('Chia sẻ'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white),
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => PdScreen(shot: widget.shot),
                          ),
                        ),
                        icon: const Icon(Icons.straighten),
                        label: const Text('Đo PD'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
