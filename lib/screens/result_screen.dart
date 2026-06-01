import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:share_plus/share_plus.dart';

import '../main.dart' show AppState, SavedLook;
import '../models/glasses.dart';
import '../services/capture_service.dart';
import '../services/result_composer.dart';
import '../theme/lumen_theme.dart';
import '../widgets/lumen_components.dart';
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
  bool _votingShown = false;

  @override
  void initState() {
    super.initState();
    _compose();
  }

  Future<void> _compose() async {
    try {
      final r = await ResultComposer.compose(
        widget.shot, widget.glasses, overlayImage: widget.overlayImage);
      if (!mounted) return;
      setState(() { _resultFile = r.file; _working = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = 'Error composing: $e'; _working = false; });
    }
  }

  Future<void> _save() async {
    if (_resultFile == null) return;
    try {
      await Gal.putImage(_resultFile!.path);
      if (!mounted) return;
      AppState.of(context).addLook(SavedLook(widget.glasses, widget.glasses.colors.first));
      _toast('Saved to My Looks ✓');
    } catch (e) {
      _toast('Could not save: $e');
    }
  }

  Future<void> _share() async {
    if (_resultFile == null) return;
    await Share.shareXFiles([XFile(_resultFile!.path)],
        text: 'Trying on "${widget.glasses.name}" from LUMEN 👓');
  }

  void _toast(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(m, style: LT.sans(13, color: LC.paper)),
      backgroundColor: LC.ink, behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.glasses;
    final cw = kColorways[item.colors.first] ?? kColorways['obsidian']!;

    return Scaffold(
      backgroundColor: LC.noir,
      body: SafeArea(
        child: Column(children: [
          LumenNavBar(dark: true, title: 'Your look', subtitle: 'Ảnh thử kính',
            onBack: () => Navigator.pop(context)),
          // Photo frame
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: Stack(children: [
                    // Photo or loading
                    Positioned.fill(child: _working
                      ? const Center(child: CircularProgressIndicator(color: LC.accent))
                      : _error != null
                        ? Center(child: Padding(padding: const EdgeInsets.all(24),
                            child: Text(_error!, style: LT.sans(13, color: LC.onNoir), textAlign: TextAlign.center)))
                        : Image.file(_resultFile!, fit: BoxFit.cover)),
                    // Info overlay
                    if (!_working && _error == null)
                      Positioned(left: 18, bottom: 18, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('LUMEN · Try-On', style: LT.eyebrow(color: LC.onNoirSoft)),
                        const SizedBox(height: 3),
                        Text(item.name, style: LT.serif(30, color: LC.onNoir)),
                        Text('${cw.name} · ${item.material} · ${item.formatPrice()}',
                          style: LT.sans(12, color: LC.onNoirSoft)),
                      ])),
                  ]),
                ),
              ),
            ),
          ),
          // Vote confirmation
          if (_votingShown)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Container(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                decoration: BoxDecoration(
                  color: const Color(0x1F7CCB8E),
                  border: Border.all(color: const Color(0x4D7CCB8E)),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(children: [
                  const Icon(Icons.share_outlined, size: 18, color: Color(0xFF7CCB8E)),
                  const SizedBox(width: 10),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Vote link copied — send to friends!', style: LT.sans(12.5, color: LC.onNoir)),
                    Text('Đã sao chép link bình chọn', style: LT.sans(10.5, color: LC.onNoirSoft)),
                  ])),
                ]),
              ),
            ),
          // Actions
          if (!_working && _error == null) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: Row(children: [
                Expanded(child: PillBtn('Save · Lưu', variant: PillVariant.glass, icon: Icons.download_outlined, onTap: _save)),
                const SizedBox(width: 10),
                Expanded(child: PillBtn('Share · Chia sẻ', variant: PillVariant.glass, icon: Icons.share_outlined, onTap: _share)),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
              child: Row(children: [
                Expanded(child: PillBtn('Get votes', variant: PillVariant.outline, dark: true, icon: Icons.thumb_up_outlined,
                  onTap: () => setState(() => _votingShown = true))),
                const SizedBox(width: 10),
                Expanded(child: PillBtn('Measure PD', icon: Icons.straighten_outlined,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PdScreen())))),
              ]),
            ),
          ],
        ]),
      ),
    );
  }
}
