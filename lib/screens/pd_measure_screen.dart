import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../services/capture_service.dart';
import '../services/pd_estimator.dart';
import '../theme/lumen_theme.dart';
import '../widgets/lumen_components.dart';

// Card-calibration PD measurement — receives a captured ProcessedShot.
// Accessed from CaptureForPdScreen after the user takes a photo.
class PdMeasureScreen extends StatefulWidget {
  final ProcessedShot shot;
  const PdMeasureScreen({super.key, required this.shot});

  @override
  State<PdMeasureScreen> createState() => _PdMeasureScreenState();
}

class _PdMeasureScreenState extends State<PdMeasureScreen> {
  Offset? _pupilL, _pupilR;
  Offset? _cardA, _cardB;
  bool _placed = false;

  void _placeInitial(Size container) {
    if (_placed) return;
    final iw = widget.shot.width.toDouble();
    final ih = widget.shot.height.toDouble();
    final scale = math.min(container.width / iw, container.height / ih);
    final dispW = iw * scale, dispH = ih * scale;
    final ox = (container.width - dispW) / 2;
    final oy = (container.height - dispH) / 2;
    Offset toDisp(double x, double y) => Offset(ox + x * scale, oy + y * scale);

    final face = widget.shot.faces.isNotEmpty ? widget.shot.faces.first : null;
    if (face != null) {
      _pupilL = toDisp(face.leftEye.dx, face.leftEye.dy);
      _pupilR = toDisp(face.rightEye.dx, face.rightEye.dy);
    } else {
      _pupilL = Offset(container.width * 0.4, container.height * 0.4);
      _pupilR = Offset(container.width * 0.6, container.height * 0.4);
    }
    _cardA = Offset(container.width * 0.3, container.height * 0.75);
    _cardB = Offset(container.width * 0.7, container.height * 0.75);
    _placed = true;
  }

  PdResult get _result => PdEstimator.estimate(
        pupilLeft: _pupilL!, pupilRight: _pupilR!,
        cardEdgeA: _cardA!, cardEdgeB: _cardB!);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LC.noir,
      body: SafeArea(
        child: Column(children: [
          LumenNavBar(dark: true, title: 'Measure PD', subtitle: 'Hiệu chỉnh bằng thẻ',
            onBack: () => Navigator.pop(context)),
          Expanded(
            child: LayoutBuilder(builder: (context, c) {
              final size = Size(c.maxWidth, c.maxHeight);
              _placeInitial(size);
              final res = _result;
              return Stack(children: [
                Positioned.fill(child: FittedBox(
                  fit: BoxFit.contain,
                  child: SizedBox(
                    width: widget.shot.width.toDouble(),
                    height: widget.shot.height.toDouble(),
                    child: RawImage(image: widget.shot.image),
                  ),
                )),
                CustomPaint(size: size, painter: _LinesPainter(_pupilL!, _pupilR!, _cardA!, _cardB!)),
                _handle(_pupilL!, LC.accent, (o) => setState(() => _pupilL = o)),
                _handle(_pupilR!, LC.accent, (o) => setState(() => _pupilR = o)),
                _handle(_cardA!, const Color(0xFFC9A86A), (o) => setState(() => _cardA = o)),
                _handle(_cardB!, const Color(0xFFC9A86A), (o) => setState(() => _cardB = o)),
                Positioned(top: 8, left: 8, right: 8, child: _legend(res)),
              ]);
            }),
          ),
        ]),
      ),
    );
  }

  Widget _handle(Offset pos, Color color, ValueChanged<Offset> onMove) {
    const r = 16.0;
    return Positioned(
      left: pos.dx - r, top: pos.dy - r,
      child: GestureDetector(
        onPanUpdate: (d) => onMove(pos + d.delta),
        child: Container(width: r * 2, height: r * 2,
          decoration: BoxDecoration(color: color.withValues(alpha: 0.35), shape: BoxShape.circle,
            border: Border.all(color: color, width: 2)),
          child: Center(child: Container(width: 4, height: 4,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)))),
      ),
    );
  }

  Widget _legend(PdResult res) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.7), borderRadius: BorderRadius.circular(14)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('🟦 Drag blue dots to each pupil · Kéo chấm xanh vào đồng tử', style: LT.sans(12, color: LC.onNoir)),
      Text('🟡 Drag gold dots to card edges · Chấm vàng căn mép thẻ', style: LT.sans(12, color: LC.onNoir)),
      const SizedBox(height: 6),
      RichText(text: TextSpan(children: [
        TextSpan(text: 'PD: ', style: LT.sans(13, color: LC.onNoirSoft, w: FontWeight.w600)),
        TextSpan(text: '${res.pdMm} mm', style: LT.serif(22, color: LC.onNoir, w: FontWeight.w600)),
      ])),
      Text('Suggested size: ${res.sizeCategory} · lens ~${res.lensWidthMin}–${res.lensWidthMax} mm',
        style: LT.sans(12, color: LC.onNoirSoft)),
      const SizedBox(height: 4),
      Text('Estimate only — not a substitute for optician measurement.',
        style: LT.sans(10.5, color: LC.onNoirSoft).copyWith(height: 1.4)),
    ]),
  );
}

class _LinesPainter extends CustomPainter {
  final Offset pL, pR, cA, cB;
  _LinesPainter(this.pL, this.pR, this.cA, this.cB);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawLine(pL, pR, Paint()..color = LC.accent..strokeWidth = 2);
    canvas.drawLine(cA, cB, Paint()..color = const Color(0xFFC9A86A)..strokeWidth = 2);
  }

  @override
  bool shouldRepaint(covariant _LinesPainter old) =>
      old.pL != pL || old.pR != pR || old.cA != cA || old.cB != cB;
}

// Keep old name as alias so capture_for_pd_screen can import either
typedef PdScreen = PdMeasureScreen;
