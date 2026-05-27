import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Kết quả ước lượng PD và gợi ý size gọng.
class PdResult {
  final double pdMm;
  final String sizeCategory; // Nhỏ / Vừa / Lớn
  final int lensWidthMin; // mm
  final int lensWidthMax; // mm

  PdResult({
    required this.pdMm,
    required this.sizeCategory,
    required this.lensWidthMin,
    required this.lensWidthMax,
  });
}

class PdEstimator {
  /// Chuẩn thẻ ID-1 (thẻ ngân hàng/ATM/CCCD): rộng 85.60 mm.
  static const double idCardWidthMm = 85.60;

  /// Tính PD (mm) từ:
  ///  - [pupilLeft], [pupilRight]: vị trí 2 đồng tử (pixel ảnh).
  ///  - [cardEdgeA], [cardEdgeB]: 2 mép thẻ người dùng đã căn (pixel ảnh),
  ///    dùng để quy đổi pixel -> mm.
  static PdResult estimate({
    required Offset pupilLeft,
    required Offset pupilRight,
    required Offset cardEdgeA,
    required Offset cardEdgeB,
  }) {
    final pdPx = (pupilRight - pupilLeft).distance;
    final cardPx = (cardEdgeB - cardEdgeA).distance;
    if (cardPx < 1) {
      return PdResult(
          pdMm: 0, sizeCategory: '—', lensWidthMin: 0, lensWidthMax: 0);
    }
    final pxPerMm = cardPx / idCardWidthMm;
    final pdMm = pdPx / pxPerMm;
    return _suggest(pdMm);
  }

  static PdResult _suggest(double pdMm) {
    String cat;
    int lo, hi;
    // Quy tắc gọng tham khảo: bề rộng tròng (lens width) ~ PD/2 ± vài mm.
    final lensCenter = (pdMm / 2).round();
    if (pdMm < 58) {
      cat = 'Nhỏ (narrow)';
    } else if (pdMm <= 66) {
      cat = 'Vừa (medium)';
    } else {
      cat = 'Lớn (wide)';
    }
    lo = (lensCenter - 2).clamp(40, 62);
    hi = (lensCenter + 3).clamp(42, 64);
    return PdResult(
      pdMm: double.parse(pdMm.toStringAsFixed(1)),
      sizeCategory: cat,
      lensWidthMin: lo,
      lensWidthMax: hi,
    );
  }
}
