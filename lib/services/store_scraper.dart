import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart';

import '../models/glasses.dart';

/// Kết quả scrape kèm thông tin tình trạng để hiển thị cho người dùng.
class ScrapeResult {
  final List<Glasses> glasses;
  final bool usedFallback; // true nếu phải dùng dữ liệu mẫu
  final String message;

  ScrapeResult(this.glasses, {this.usedFallback = false, this.message = ''});
}

/// Scraper "best-effort".
///
/// LƯU Ý THẲNG THẮN:
/// - Không có scraper nào chạy đúng cho MỌI website. Mỗi site cấu trúc khác nhau,
///   nhiều site render bằng JavaScript nên HTML thô tải về sẽ thiếu sản phẩm.
/// - Chiến lược ở đây: thử nhiều cách từ đáng tin -> đoán mò:
///     1) Đọc JSON-LD schema.org/Product (chuẩn, nhiều site thương mại có).
///     2) Đọc thẻ OpenGraph / meta.
///     3) Heuristic: tìm ảnh + text có chứa từ khoá kính.
/// - Nếu không ra gì -> trả về catalog mẫu để app vẫn dùng được.
class StoreScraper {
  static const _eyewearKeywords = [
    'kính', 'kinh mat', 'kính mắt', 'gọng', 'glass', 'glasses',
    'eyewear', 'eyeglass', 'frame', 'sunglass', 'optic', 'spectacle',
  ];

  /// [input] có thể là URL đầy đủ hoặc tên cửa hàng.
  Future<ScrapeResult> fetchGlasses(String input) async {
    final trimmed = input.trim();
    if (trimmed.isEmpty) {
      return ScrapeResult(kDemoGlasses,
          usedFallback: true, message: 'Chưa nhập gì, dùng catalog mẫu.');
    }

    final url = _normalizeToUrl(trimmed);
    if (url == null) {
      // Không phải URL -> đây là TÊN cửa hàng.
      // App này không tích hợp search engine API, nên không thể "tìm theo tên"
      // một cách tin cậy. Trả mẫu và hướng dẫn người dùng dán link.
      return ScrapeResult(
        kDemoGlasses,
        usedFallback: true,
        message:
            'Mình chưa có API tìm kiếm theo tên cửa hàng. Hãy dán LINK trang sản '
            'phẩm/danh mục kính để quét chính xác. Tạm hiển thị catalog mẫu.',
      );
    }

    try {
      final res = await http
          .get(Uri.parse(url), headers: {
            'User-Agent':
                'Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 '
                '(KHTML, like Gecko) Chrome/120 Mobile Safari/537.36',
            'Accept': 'text/html,application/xhtml+xml',
          })
          .timeout(const Duration(seconds: 15));

      if (res.statusCode != 200) {
        return ScrapeResult(kDemoGlasses,
            usedFallback: true,
            message: 'Không tải được trang (HTTP ${res.statusCode}). Dùng mẫu.');
      }

      final doc = html_parser.parse(res.body);
      final base = Uri.parse(url);

      final found = <Glasses>[];
      found.addAll(_fromJsonLd(doc, base));
      if (found.isEmpty) found.addAll(_fromHeuristic(doc, base));

      final filtered = _dedupe(found);
      if (filtered.isEmpty) {
        return ScrapeResult(kDemoGlasses,
            usedFallback: true,
            message:
                'Quét xong nhưng không nhận diện được sản phẩm kính (trang có thể '
                'dùng JavaScript). Dùng catalog mẫu để bạn thử AR.');
      }

      return ScrapeResult(filtered,
          message: 'Tìm thấy ${filtered.length} mẫu từ cửa hàng.');
    } catch (e) {
      return ScrapeResult(kDemoGlasses,
          usedFallback: true, message: 'Lỗi khi quét: $e. Dùng catalog mẫu.');
    }
  }

  // ---- Chiến lược 1: JSON-LD schema.org/Product ----
  List<Glasses> _fromJsonLd(Document doc, Uri base) {
    final out = <Glasses>[];
    final scripts =
        doc.querySelectorAll('script[type="application/ld+json"]');
    var i = 0;
    for (final s in scripts) {
      try {
        final data = jsonDecode(s.text);
        for (final node in _flattenJsonLd(data)) {
          if (node is! Map) continue;
          final type = node['@type'];
          final isProduct = (type == 'Product') ||
              (type is List && type.contains('Product'));
          if (!isProduct) continue;

          final name = (node['name'] ?? '').toString();
          if (!_looksLikeEyewear(name)) continue;

          String? img;
          final image = node['image'];
          if (image is String) img = image;
          if (image is List && image.isNotEmpty) img = image.first.toString();
          if (image is Map) img = image['url']?.toString();

          String? price;
          final offers = node['offers'];
          if (offers is Map) price = offers['price']?.toString();
          if (offers is List && offers.isNotEmpty && offers.first is Map) {
            price = offers.first['price']?.toString();
          }

          out.add(Glasses(
            id: 'jsonld_${i++}',
            name: name,
            price: price,
            thumbnailUrl: img == null ? null : _abs(base, img),
            shape: _guessShape(name),
            productUrl: node['url']?.toString(),
          ));
        }
      } catch (_) {
        // JSON-LD lỗi cú pháp -> bỏ qua
      }
    }
    return out;
  }

  // ---- Chiến lược 2: Heuristic ảnh + text ----
  List<Glasses> _fromHeuristic(Document doc, Uri base) {
    final out = <Glasses>[];
    var i = 0;

    // Tìm các "card" sản phẩm phổ biến.
    final candidates = <Element>[
      ...doc.querySelectorAll('[class*="product"]'),
      ...doc.querySelectorAll('[class*="item"]'),
      ...doc.querySelectorAll('li'),
      ...doc.querySelectorAll('article'),
    ];

    for (final el in candidates) {
      final img = el.querySelector('img');
      if (img == null) continue;

      final text = el.text.replaceAll(RegExp(r'\s+'), ' ').trim();
      final altSrc =
          '${img.attributes['alt'] ?? ''} ${img.attributes['src'] ?? ''}';

      if (!_looksLikeEyewear('$text $altSrc')) continue;

      final src = img.attributes['src'] ??
          img.attributes['data-src'] ??
          img.attributes['data-original'];
      if (src == null) continue;

      // Lấy tên ngắn gọn
      final name = (img.attributes['alt']?.trim().isNotEmpty == true)
          ? img.attributes['alt']!.trim()
          : (text.length > 60 ? '${text.substring(0, 60)}…' : text);

      out.add(Glasses(
        id: 'h_${i++}',
        name: name.isEmpty ? 'Mẫu kính ${i}' : name,
        price: _extractPrice(text),
        thumbnailUrl: _abs(base, src),
        shape: _guessShape('$name $text'),
      ));
      if (out.length >= 40) break;
    }
    return out;
  }

  // ---------- helpers ----------

  Iterable<dynamic> _flattenJsonLd(dynamic data) sync* {
    if (data is List) {
      for (final e in data) {
        yield* _flattenJsonLd(e);
      }
    } else if (data is Map) {
      yield data;
      if (data['@graph'] != null) yield* _flattenJsonLd(data['@graph']);
    }
  }

  bool _looksLikeEyewear(String text) {
    final t = text.toLowerCase();
    return _eyewearKeywords.any((k) => t.contains(k));
  }

  FrameShape _guessShape(String text) {
    final t = text.toLowerCase();
    if (t.contains('round') || t.contains('tròn')) return FrameShape.round;
    if (t.contains('cat') || t.contains('mèo')) return FrameShape.catEye;
    if (t.contains('aviator') || t.contains('phi công')) {
      return FrameShape.aviator;
    }
    return FrameShape.rectangle;
  }

  String? _extractPrice(String text) {
    final m = RegExp(r'(\d[\d.,]{2,})\s*(đ|vnđ|vnd|₫|\$)',
            caseSensitive: false)
        .firstMatch(text);
    return m?.group(0);
  }

  String _abs(Uri base, String src) {
    if (src.startsWith('//')) return '${base.scheme}:$src';
    if (src.startsWith('http')) return src;
    return base.resolve(src).toString();
  }

  List<Glasses> _dedupe(List<Glasses> list) {
    final seen = <String>{};
    final out = <Glasses>[];
    for (final g in list) {
      final key = g.thumbnailUrl ?? g.name;
      if (seen.add(key)) out.add(g);
    }
    return out;
  }

  Uri? _normalizeToUrl(String input) {
    var s = input;
    if (s.startsWith('http://') || s.startsWith('https://')) {
      return Uri.tryParse(s);
    }
    // Nếu trông giống domain (có dấu chấm, không có dấu cách) thì thêm https://
    if (s.contains('.') && !s.contains(' ')) {
      return Uri.tryParse('https://$s');
    }
    return null; // coi như tên cửa hàng
  }
}
