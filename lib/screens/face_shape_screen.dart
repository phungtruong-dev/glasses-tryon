import 'dart:math';
import 'package:flutter/material.dart';

import '../models/glasses.dart';
import '../theme/lumen_theme.dart';
import '../widgets/frame_painter.dart';
import '../widgets/lumen_components.dart';
import 'tryon_screen.dart';

class FaceShapeScreen extends StatefulWidget {
  const FaceShapeScreen({super.key});

  @override
  State<FaceShapeScreen> createState() => _FaceShapeScreenState();
}

class _FaceShapeScreenState extends State<FaceShapeScreen> {
  _Phase _phase = _Phase.intro;
  String _shapeKey = 'oval';

  void _start() {
    setState(() => _phase = _Phase.scanning);
    final keys = kFaceShapes.keys.toList();
    final key = keys[Random().nextInt(keys.length)];
    Future.delayed(const Duration(milliseconds: 2600), () {
      if (mounted) setState(() { _shapeKey = key; _phase = _Phase.result; });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LC.noir,
      body: SafeArea(
        child: Column(children: [
          LumenNavBar(dark: true, title: 'Face shape', subtitle: 'Phân tích dáng mặt',
            onBack: () => Navigator.pop(context)),
          Expanded(child: _phase == _Phase.result ? _ResultView(shapeKey: _shapeKey) : _ScanView(phase: _phase, onStart: _start)),
        ]),
      ),
    );
  }
}

enum _Phase { intro, scanning, result }

// ── Scan / Intro view ────────────────────────────────────────────────────────

class _ScanView extends StatelessWidget {
  final _Phase phase;
  final VoidCallback onStart;
  const _ScanView({super.key, required this.phase, required this.onStart});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: Stack(children: [
            // Portrait silhouette background
            Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(center: Alignment(0, -0.3), radius: 1,
                  colors: [Color(0xFF322D23), Color(0xFF1C1912), Color(0xFF0F0D09)]),
              ),
            ),
            // Face silhouette
            Center(child: _FaceSilhouette()),
            // Scanning mesh overlay
            if (phase == _Phase.scanning) const _MeshOverlay(),
            // Bottom panel
            Positioned(
              left: 0, right: 0, bottom: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(22, 24, 22, 26),
                decoration: BoxDecoration(
                  gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withValues(alpha: 0.9)]),
                ),
                child: phase == _Phase.intro ? _introContent(context) : _scanningContent(),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _introContent(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text('Find your face shape', style: LT.serif(26, color: LC.onNoir)),
    const SizedBox(height: 8),
    Text('Center your face and hold still. We map 68 points to detect your shape and recommend frames.',
      style: LT.sans(13, color: LC.onNoirSoft).copyWith(height: 1.5)),
    Text('Giữ khuôn mặt cân giữa khung hình.', style: LT.sans(13, color: LC.onNoirSoft, w: FontWeight.w500)),
    const SizedBox(height: 18),
    PillBtn('Analyze · Phân tích', icon: Icons.auto_awesome_outlined, full: true, onTap: onStart),
  ]);

  Widget _scanningContent() => Column(children: [
    Text('Mapping your features…', style: LT.serif(22, color: LC.onNoir)),
    Text('Đang phân tích đường nét khuôn mặt', style: LT.sans(12, color: LC.onNoirSoft)),
  ]);
}

class _FaceSilhouette extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(double.infinity, double.infinity),
      painter: _SilhouettePainter(),
    );
  }
}

class _SilhouettePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = const Color(0xFF3A3329)..style = PaintingStyle.fill;
    final cx = size.width / 2;
    // Head oval
    canvas.drawOval(Rect.fromCenter(center: Offset(cx, size.height * 0.38), width: size.width * 0.52, height: size.height * 0.62), p);
    // Shoulders
    final s = Paint()..color = const Color(0xFF2A2520)..style = PaintingStyle.fill;
    final sp = Path()
      ..moveTo(cx - size.width * 0.42, size.height)
      ..quadraticBezierTo(cx, size.height * 0.82, cx + size.width * 0.42, size.height)
      ..close();
    canvas.drawPath(sp, s);
  }

  @override
  bool shouldRepaint(_) => false;
}

class _MeshOverlay extends StatefulWidget {
  const _MeshOverlay();

  @override
  State<_MeshOverlay> createState() => _MeshOverlayState();
}

class _MeshOverlayState extends State<_MeshOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000))..forward();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final pts = <Widget>[];
        for (var i = 0; i < 46; i++) {
          final a = (i / 46) * 2 * pi;
          final rx = 0.13 + (i % 5) * 0.006;
          final ry = 0.18 + (i % 4) * 0.005;
          final lx = 0.5 + cos(a) * rx;
          final ly = 0.35 + sin(a) * ry;
          final delay = i * 0.02;
          final opacity = (_ctrl.value - delay).clamp(0.0, 1.0);
          pts.add(Positioned(
            left: lx * double.infinity,
            top: ly * double.infinity,
            child: FractionalTranslation(
              translation: const Offset(-0.5, -0.5),
              child: Opacity(
                opacity: opacity,
                child: Container(
                  width: 4, height: 4,
                  decoration: const BoxDecoration(color: LC.accent, shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: LC.accent, blurRadius: 6)]),
                ),
              ),
            ),
          ));
        }
        return LayoutBuilder(builder: (context, constraints) {
          return Stack(children: [
            for (var i = 0; i < 46; i++) _buildDot(i, constraints),
          ]);
        });
      },
    );
  }

  Widget _buildDot(int i, BoxConstraints c) {
    final a = (i / 46) * 2 * pi;
    final rx = c.maxWidth * (0.13 + (i % 5) * 0.006);
    final ry = c.maxHeight * (0.18 + (i % 4) * 0.005);
    final x = c.maxWidth * 0.5 + cos(a) * rx;
    final y = c.maxHeight * 0.35 + sin(a) * ry;
    final delay = i * 0.02;
    final opacity = (_ctrl.value - delay).clamp(0.0, 1.0);
    return Positioned(
      left: x - 2, top: y - 2,
      child: Opacity(opacity: opacity,
        child: Container(width: 4, height: 4,
          decoration: const BoxDecoration(color: LC.accent, shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: LC.accent, blurRadius: 6)]))),
    );
  }
}

// ── Result view ──────────────────────────────────────────────────────────────

class _ResultView extends StatelessWidget {
  final String shapeKey;
  const _ResultView({required this.shapeKey});

  @override
  Widget build(BuildContext context) {
    final fs = kFaceShapes[shapeKey]!;
    final recs = kCatalog.where((f) => fs.bestShapes.contains(f.shape.name)).take(6).toList();

    return SingleChildScrollView(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Hero card with face result
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
          child: Container(
            height: 260,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: Stack(children: [
                Container(decoration: const BoxDecoration(
                  gradient: RadialGradient(center: Alignment(0, -0.3), radius: 1,
                    colors: [Color(0xFF322D23), Color(0xFF1C1912), Color(0xFF0F0D09)]))),
                Center(child: _FaceSilhouette()),
                Positioned(
                  bottom: 0, left: 0, right: 0,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(18, 20, 18, 16),
                    decoration: BoxDecoration(gradient: LinearGradient(
                      begin: Alignment.topCenter, end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black.withValues(alpha: 0.85)])),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Detected · Kết quả', style: LT.eyebrow(color: LC.onNoirSoft)),
                      const SizedBox(height: 3),
                      RichText(text: TextSpan(children: [
                        TextSpan(text: '${fs.name} ', style: LT.serif(34, color: LC.onNoir)),
                        TextSpan(text: 'face', style: LT.serif(24, color: LC.accent, style: FontStyle.italic)),
                      ])),
                      Text('${fs.vn} · 92% match', style: LT.sans(12, color: LC.onNoirSoft)),
                    ]),
                  ),
                ),
              ]),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 6),
          child: Text(fs.blurb, style: LT.sans(13.5, color: LC.onNoirSoft).copyWith(height: 1.55)),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
          child: Text('Frames that flatter you', style: LT.serif(22, color: LC.onNoir)),
        ),
        Text('Gọng kính hợp với bạn nhất', style: LT.sans(12, color: LC.onNoirSoft, w: FontWeight.w500)).paddingLeft(20),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.0),
          itemCount: recs.length,
          itemBuilder: (_, i) => _RecCard(item: recs[i]),
        ),
      ]),
    );
  }
}

class _RecCard extends StatelessWidget {
  final Glasses item;
  const _RecCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final cw = kColorways[item.colors.first] ?? kColorways['obsidian']!;
    final frameColor = cw.hex == const Color(0xFF23201C) ? const Color(0xFFD7CFC0) : cw.hex;
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(
        builder: (_) => TryOnScreen(initialGlasses: item, catalog: kCatalog))),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Column(children: [
          Expanded(child: Center(child: FractionallySizedBox(
            widthFactor: 0.72,
            child: FrameWidget(shape: item.shape, frameColor: frameColor, lensColor: const Color(0xFF8A98A6), temples: false),
          ))),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 11),
            child: Row(children: [
              Text(item.name, style: LT.serif(16, color: LC.onNoir)),
              const Spacer(),
              Text('Try on →', style: LT.sans(11.5, w: FontWeight.w600, color: LC.accent)),
            ]),
          ),
        ]),
      ),
    );
  }
}

extension _PaddingExt on Widget {
  Widget paddingLeft(double v) => Padding(padding: EdgeInsets.only(left: v), child: this);
}
