import 'dart:math';
import 'package:flutter/material.dart';

import '../models/glasses.dart';
import '../theme/lumen_theme.dart';
import '../widgets/frame_painter.dart';
import '../widgets/lumen_components.dart';
import 'capture_for_pd_screen.dart';
import 'product_screen.dart';

class PdScreen extends StatefulWidget {
  const PdScreen({super.key});

  @override
  State<PdScreen> createState() => _PdScreenState();
}

class _PdScreenState extends State<PdScreen> {
  bool _autoMode = true;
  _Phase _phase = _Phase.idle;
  int _pd = 63;

  @override
  void initState() {
    super.initState();
    if (_autoMode) _startScan();
  }

  void _startScan() {
    setState(() => _phase = _Phase.scanning);
    Future.delayed(const Duration(milliseconds: 2400), () {
      if (!mounted) return;
      setState(() {
        _pd = 62 + Random().nextInt(4);
        _phase = _Phase.done;
      });
    });
  }

  void _setMode(bool auto) {
    setState(() { _autoMode = auto; _phase = _Phase.idle; });
    if (auto) _startScan();
  }

  _SizeInfo get _size {
    if (_pd < 61) return _SizeInfo('Narrow', 'Nhỏ', 48, 51);
    if (_pd <= 65) return _SizeInfo('Medium', 'Vừa', 51, 54);
    return _SizeInfo('Wide', 'Rộng', 54, 58);
  }

  List<Glasses> get _recs => kCatalog.where((f) => f.width == _size.cat).take(4).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LC.noir,
      body: SafeArea(
        child: Column(children: [
          LumenNavBar(dark: true, title: 'Measure PD', subtitle: 'Đo khoảng cách đồng tử',
            onBack: () => Navigator.pop(context)),
          // Method toggle
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(children: [
              _ModeBtn(label: 'Auto', vn: 'Tự động', active: _autoMode, onTap: () => _setMode(true)),
              const SizedBox(width: 6),
              _ModeBtn(label: 'With card', vn: 'Dùng thẻ', active: !_autoMode, onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const CaptureForPdScreen()));
              }),
            ]),
          ),
          // Camera view
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: Stack(children: [
                    _Background(),
                    if (_phase == _Phase.done) _PupilMarkers(),
                    if (_phase == _Phase.scanning) _ScanLine(),
                    // Readout card
                    Positioned(top: 12, left: 12, right: 12, child: Center(child: _Readout(phase: _phase, pd: _pd, auto: _autoMode))),
                  ]),
                ),
              ),
            ),
          ),
          // Results
          if (_phase == _Phase.done)
            _ResultPanel(size: _size, recs: _recs, pd: _pd),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }
}

enum _Phase { idle, scanning, done }

class _SizeInfo {
  final String cat, vn;
  final int lo, hi;
  const _SizeInfo(this.cat, this.vn, this.lo, this.hi);
}

class _ModeBtn extends StatelessWidget {
  final String label, vn;
  final bool active;
  final VoidCallback onTap;
  const _ModeBtn({required this.label, required this.vn, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) => Expanded(child: GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: active ? LC.accent : Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: active ? LC.accent : Colors.white.withValues(alpha: 0.14)),
      ),
      child: Column(children: [
        Text(label, style: LT.sans(13, w: FontWeight.w600, color: active ? Colors.white : LC.onNoirSoft)),
        Text('· $vn', style: LT.sans(11, color: active ? Colors.white.withValues(alpha: 0.7) : LC.onNoirSoft, w: FontWeight.w500)),
      ]),
    ),
  ));
}

class _Background extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    decoration: const BoxDecoration(gradient: RadialGradient(center: Alignment(0, -0.3), radius: 1,
      colors: [Color(0xFF322D23), Color(0xFF1C1912), Color(0xFF0F0D09)])),
  );
}

class _PupilMarkers extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (_, c) {
      final lx = c.maxWidth * 0.40, rx = c.maxWidth * 0.60, y = c.maxHeight * 0.36;
      return Stack(children: [
        // Measurement line
        Positioned(left: lx, right: c.maxWidth - rx, top: y - 1, child: Container(height: 2, color: LC.accent,
          decoration: BoxDecoration(boxShadow: [BoxShadow(color: LC.accent, blurRadius: 10)]))),
        _Pupil(left: lx, top: y),
        _Pupil(left: rx, top: y),
      ]);
    });
  }
}

class _Pupil extends StatelessWidget {
  final double left, top;
  const _Pupil({required this.left, required this.top});

  @override
  Widget build(BuildContext context) => Positioned(
    left: left - 8, top: top - 8,
    child: Container(width: 16, height: 16, decoration: BoxDecoration(
      shape: BoxShape.circle,
      border: Border.all(color: LC.accent, width: 2),
      color: LC.accent.withValues(alpha: 0.25),
    ), child: Center(child: Container(width: 4, height: 4, decoration: const BoxDecoration(color: LC.accent, shape: BoxShape.circle)))),
  );
}

class _ScanLine extends StatefulWidget {
  @override
  State<_ScanLine> createState() => _ScanLineState();
}

class _ScanLineState extends State<_ScanLine> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200))..forward();
    _anim = Tween(begin: 0.08, end: 0.88).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (_, c) => AnimatedBuilder(
    animation: _anim,
    builder: (_, __) => Positioned(
      left: c.maxWidth * 0.08, right: c.maxWidth * 0.08,
      top: c.maxHeight * _anim.value - 1,
      child: Container(height: 2,
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Colors.transparent, LC.accent, Colors.transparent]),
          boxShadow: [BoxShadow(color: LC.accent, blurRadius: 16)],
          borderRadius: BorderRadius.circular(2),
        )),
    ),
  ));
}

class _Readout extends StatelessWidget {
  final _Phase phase;
  final int pd;
  final bool auto;
  const _Readout({super.key, required this.phase, required this.pd, required this.auto});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
    decoration: BoxDecoration(
      color: Colors.black.withValues(alpha: 0.62),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
    ),
    child: phase == _Phase.done
      ? Column(children: [
          Text('YOUR PD · PD CỦA BẠN', style: LT.eyebrow(color: LC.onNoirSoft)),
          const SizedBox(height: 2),
          RichText(text: TextSpan(children: [
            TextSpan(text: '$pd', style: LT.serif(38, color: LC.onNoir)),
            TextSpan(text: ' mm', style: LT.serif(18, color: LC.onNoir)),
          ])),
        ])
      : Text(phase == _Phase.scanning ? 'Detecting pupils… · Đang đo…' : (auto ? 'Ready to scan' : 'Hold card under your eyes'),
          style: LT.sans(13, w: FontWeight.w600, color: LC.onNoir)),
  );
}

class _ResultPanel extends StatelessWidget {
  final _SizeInfo size;
  final List<Glasses> recs;
  final int pd;
  const _ResultPanel({super.key, required this.size, required this.recs, required this.pd});

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(maxHeight: 260),
    child: SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          _InfoCard(label: 'Frame size · Cỡ gọng', value: size.cat, vn: size.vn),
          const SizedBox(width: 10),
          _InfoCard(label: 'Lens width · Bề rộng', value: '${size.lo}–${size.hi}', vn: 'mm'),
        ]),
        const SizedBox(height: 12),
        Text('Frames in your size · Gọng vừa cỡ', style: LT.sans(11.5, color: LC.onNoirSoft)),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: recs.map((f) => GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductScreen(item: f))),
            child: Container(
              width: 92, margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.06),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)), borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.fromLTRB(8, 10, 8, 9),
              child: Column(children: [
                FrameWidget(shape: f.shape, frameColor: const Color(0xFFD7CFC0), lensColor: const Color(0xFF8A98A6), temples: false),
                const SizedBox(height: 4),
                Text(f.name, style: LT.sans(11, w: FontWeight.w600, color: LC.onNoir)),
              ]),
            ),
          )).toList()),
        ),
        const SizedBox(height: 8),
        Text('Estimate only — not a substitute for an optician\'s measurement.',
          style: LT.sans(10.5, color: LC.onNoirSoft).copyWith(height: 1.5)),
      ]),
    ),
  );
}

class _InfoCard extends StatelessWidget {
  final String label, value, vn;
  const _InfoCard({super.key, required this.label, required this.value, required this.vn});

  @override
  Widget build(BuildContext context) => Expanded(child: Container(
    padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.06),
      border: Border.all(color: Colors.white.withValues(alpha: 0.1)), borderRadius: BorderRadius.circular(14)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: LT.eyebrow(color: LC.onNoirSoft)),
      const SizedBox(height: 4),
      RichText(text: TextSpan(children: [
        TextSpan(text: value, style: LT.serif(22, color: LC.onNoir)),
        TextSpan(text: '  $vn', style: LT.sans(13, color: LC.onNoirSoft)),
      ])),
    ]),
  ));
}
