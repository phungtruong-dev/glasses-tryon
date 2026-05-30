import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../services/capture_service.dart';
import '../services/pd_estimator.dart';

/// Measure pupillary distance using a credit-card calibration method.
/// PD(px) / card-edge(px) ratio is display-size-independent, so all
/// measurements happen directly in widget coordinates.
class PdScreen extends StatefulWidget {
  final ProcessedShot shot;
  const PdScreen({super.key, required this.shot});

  @override
  State<PdScreen> createState() => _PdScreenState();
}

class _PdScreenState extends State<PdScreen> {
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
    Offset toDisp(double x, double y) =>
        Offset(ox + x * scale, oy + y * scale);

    // Use FaceResult.leftEye/rightEye (already pixel coords in image space).
    final face =
        widget.shot.faces.isNotEmpty ? widget.shot.faces.first : null;
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
        pupilLeft: _pupilL!,
        pupilRight: _pupilR!,
        cardEdgeA: _cardA!,
        cardEdgeB: _cardB!,
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Đo PD & gợi ý size'),
      ),
      body: Column(
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, c) {
                final size = Size(c.maxWidth, c.maxHeight);
                _placeInitial(size);
                final res = _result;
                return Stack(
                  children: [
                    Positioned.fill(
                      child: FittedBox(
                        fit: BoxFit.contain,
                        child: SizedBox(
                          width: widget.shot.width.toDouble(),
                          height: widget.shot.height.toDouble(),
                          child: RawImage(image: widget.shot.image),
                        ),
                      ),
                    ),
                    CustomPaint(
                      size: size,
                      painter: _LinesPainter(
                          _pupilL!, _pupilR!, _cardA!, _cardB!),
                    ),
                    _handle(_pupilL!, Colors.cyan,
                        (o) => setState(() => _pupilL = o)),
                    _handle(_pupilR!, Colors.cyan,
                        (o) => setState(() => _pupilR = o)),
                    _handle(_cardA!, Colors.amber,
                        (o) => setState(() => _cardA = o)),
                    _handle(_cardB!, Colors.amber,
                        (o) => setState(() => _cardB = o)),
                    Positioned(
                      top: 8,
                      left: 8,
                      right: 8,
                      child: _legend(res),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _handle(Offset pos, Color color, ValueChanged<Offset> onMove) {
    const r = 16.0;
    return Positioned(
      left: pos.dx - r,
      top: pos.dy - r,
      child: GestureDetector(
        onPanUpdate: (d) => onMove(pos + d.delta),
        child: Container(
          width: r * 2,
          height: r * 2,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.35),
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 2),
          ),
          child: Center(
            child: Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
          ),
        ),
      ),
    );
  }

  Widget _legend(PdResult res) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DefaultTextStyle(
        style: const TextStyle(color: Colors.white, fontSize: 13),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('🟦 Kéo 2 chấm xanh vào tâm 2 đồng tử.'),
            const Text(
                '🟨 Kéo 2 chấm vàng trùng 2 mép NGANG của thẻ ngân hàng.'),
            const SizedBox(height: 6),
            Text('PD ước lượng: ${res.pdMm} mm',
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold)),
            Text('Gợi ý gọng: ${res.sizeCategory} • '
                'bề rộng tròng ~${res.lensWidthMin}–${res.lensWidthMax} mm'),
            const SizedBox(height: 4),
            const Text(
              'Lưu ý: đây là ƯỚC LƯỢNG để chọn size, không thay thế đo khám '
              'tại cửa hàng/bác sĩ.',
              style: TextStyle(fontSize: 11, color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}

class _LinesPainter extends CustomPainter {
  final Offset pL, pR, cA, cB;
  _LinesPainter(this.pL, this.pR, this.cA, this.cB);

  @override
  void paint(Canvas canvas, Size size) {
    final blue = Paint()
      ..color = Colors.cyan
      ..strokeWidth = 2;
    final amber = Paint()
      ..color = Colors.amber
      ..strokeWidth = 2;
    canvas.drawLine(pL, pR, blue);
    canvas.drawLine(cA, cB, amber);
  }

  @override
  bool shouldRepaint(covariant _LinesPainter old) =>
      old.pL != pL || old.pR != pR || old.cA != cA || old.cB != cB;
}
