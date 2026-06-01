import 'dart:convert';
import 'dart:ui';
import 'package:http/http.dart' as http;

import '../models/glasses.dart';

/// Lấy danh sách kính từ backend (xem thư mục backend/ FastAPI).
/// Đây là cách ĐÁNG TIN CẬY hơn scrape: cửa hàng tự upload sản phẩm + ảnh PNG
/// tách nền chuẩn để overlay đẹp.
class ApiService {
  final String baseUrl; // vd: http://10.0.2.2:8000 (emulator) hoặc IP LAN

  ApiService(this.baseUrl);

  Future<List<Glasses>> fetchStoreProducts(String storeId) async {
    final uri = Uri.parse('$baseUrl/stores/$storeId/products');
    final res = await http.get(uri).timeout(const Duration(seconds: 15));
    if (res.statusCode != 200) {
      throw Exception('Backend trả về HTTP ${res.statusCode}');
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final items = (data['products'] as List).cast<Map<String, dynamic>>();

    return items.map((p) {
      final overlay = p['overlay_url'] as String?;
      return Glasses(
        id: p['id'].toString(),
        name: (p['name'] ?? 'Kính').toString(),
        price: _parsePrice(p['price']?.toString()),
        thumbnailUrl: (p['thumbnail_url'] ?? overlay)?.toString(),
        // overlay_url là ảnh PNG tách nền dùng để dán lên mặt.
        overlayAsset: overlay == null ? null : _abs(overlay),
        shape: _shapeFrom(p['shape']?.toString()),
        frameColor: _colorFrom(p['color']?.toString()),
      );
    }).toList();
  }

  int _parsePrice(String? s) {
    if (s == null) return 0;
    final digits = s.replaceAll(RegExp(r'[^\d]'), '');
    return int.tryParse(digits) ?? 0;
  }

  String _abs(String path) {
    if (path.startsWith('http')) return path;
    return '$baseUrl$path';
  }

  FrameShape _shapeFrom(String? s) {
    switch (s) {
      case 'round':
        return FrameShape.round;
      case 'catEye':
        return FrameShape.catEye;
      case 'aviator':
        return FrameShape.aviator;
      default:
        return FrameShape.rectangle;
    }
  }

  Color _colorFrom(String? hex) {
    if (hex == null) return const Color(0xFF222222);
    var h = hex.replaceAll('#', '');
    if (h.length == 6) h = 'FF$h';
    final v = int.tryParse(h, radix: 16);
    return v == null ? const Color(0xFF222222) : Color(v);
  }
}
