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
/// Chiến lược từ đáng tin → đoán mò:
///  1) JSON-LD schema.org/Product
///  2) Heuristic: card sản phẩm có ảnh + từ khoá kính
///  3) Deep-fetch: lấy link /san-pham/ | /product/ rồi fetch từng trang con
class StoreScraper {
  static const _eyewearKeywords = [
    'kính',
    'kinh mat',
    'kính mắt',
    'gọng',
    'glass',
    'glasses',
    'eyewear',
    'eyeglass',
    'frame',
    'sunglass',
    'optic',
    'spectacle',
  ];

  // URL path patterns that indicate a product detail page.
  static const _productPathPatterns = [
    '/san-pham/',
    '/product/',
    '/products/',
    '/hang-hoa/',
    '/mat-kinh/',
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
      return ScrapeResult(
        kDemoGlasses,
        usedFallback: true,
        message:
            'Mình chưa có API tìm kiếm theo tên cửa hàng. Hãy dán LINK trang sản '
            'phẩm/danh mục kính để quét chính xác. Tạm hiển thị catalog mẫu.',
      );
    }

    try {
      final res = await _get(url).timeout(const Duration(seconds: 15));

      if (res.statusCode != 200) {
        return ScrapeResult(kDemoGlasses,
            usedFallback: true,
            message:
                'Không tải được trang (HTTP ${res.statusCode}). Dùng mẫu.');
      }

      final doc = html_parser.parse(res.body);

      final found = <Glasses>[];
      found.addAll(_fromJsonLd(doc, url));
      if (found.isEmpty) found.addAll(_fromHeuristic(doc, url));
      if (found.isEmpty) found.addAll(await _fromDeepFetch(doc, url));

      final filtered = _dedupe(found);
      if (filtered.isEmpty) {
        return ScrapeResult(kDemoGlasses,
            usedFallback: true,
            message:
                'Quét xong nhưng không nhận diện được sản phẩm kính. Dùng catalog mẫu.');
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
    final scripts = doc.querySelectorAll('script[type="application/ld+json"]');
    var i = 0;
    for (final s in scripts) {
      try {
        final data = jsonDecode(s.text);
        for (final node in _flattenJsonLd(data)) {
          if (node is! Map) continue;
          final type = node['@type'];
          final isProduct =
              (type == 'Product') || (type is List && type.contains('Product'));
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
      } catch (_) {}
    }
    return out;
  }

  // ---- Chiến lược 2: Heuristic card sản phẩm ----
  List<Glasses> _fromHeuristic(Document doc, Uri base) {
    final out = <Glasses>[];
    var i = 0;

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

      final rawSrc = img.attributes['src'] ??
          img.attributes['data-src'] ??
          img.attributes['data-original'];
      if (rawSrc == null) continue;

      // Decode Next.js /_next/image?url=ENCODED into the real URL.
      final src = _decodeNextImageSrc(rawSrc) ?? rawSrc;

      // Skip placeholder images.
      if (src.contains('/img/no_image') || src.contains('no_image')) continue;

      final name = (img.attributes['alt']?.trim().isNotEmpty == true)
          ? img.attributes['alt']!.trim()
          : (text.length > 60 ? '${text.substring(0, 60)}…' : text);

      out.add(Glasses(
        id: 'h_${i++}',
        name: name.isEmpty ? 'Mẫu kính $i' : name,
        price: _extractPrice(text),
        thumbnailUrl: _abs(base, src),
        shape: _guessShape('$name $text'),
      ));
      if (out.length >= 40) break;
    }
    return out;
  }

  // ---- Chiến lược 3: Deep-fetch từng trang sản phẩm ----
  //
  // Khi heuristic thất bại (trang dùng JS lazy-load ảnh như Next.js),
  // tìm href khớp product-path pattern rồi fetch tối đa 15 trang con.
  Future<List<Glasses>> _fromDeepFetch(Document doc, Uri base) async {
    final slugs = _collectProductLinks(doc, base);
    if (slugs.isEmpty) return [];

    final limit = slugs.take(15).toList();
    final results = <Glasses>[];
    var i = 0;

    for (final productUrl in limit) {
      try {
        final res =
            await _get(productUrl).timeout(const Duration(seconds: 10));
        if (res.statusCode != 200) continue;

        final pdoc = html_parser.parse(res.body);
        final g = _fromProductPage(pdoc, productUrl, i++);
        if (g != null) results.add(g);
      } catch (_) {
        // skip failed pages
      }
    }
    return results;
  }

  /// Extracts a single [Glasses] from an individual product page.
  Glasses? _fromProductPage(Document doc, Uri pageUrl, int idx) {
    // Title: prefer <h1>, fall back to <title> with site-name stripped.
    final h1 = doc.querySelector('h1')?.text.trim();
    final titleTag = doc.querySelector('title')?.text.trim();
    final rawName = h1?.isNotEmpty == true
        ? h1!
        : (titleTag ?? '').replaceAll(RegExp(r'\s*[-|–|,]\s*[^-|–]+$'), '').trim();
    if (rawName.isEmpty) return null;

    // Best product image: prefer WP uploads path (actual product photos).
    String? imgUrl;
    for (final img in doc.querySelectorAll('img')) {
      final src = img.attributes['src'] ?? '';
      final decoded = _decodeNextImageSrc(src) ?? src;
      if (decoded.contains('no_image') ||
          decoded.contains('/img/') ||
          !decoded.startsWith('http')) { continue; }
      imgUrl = decoded;
      // Stop early if this looks like a clean product photo.
      if (decoded.contains('/wp-content/uploads/') ||
          decoded.toLowerCase().contains('whitebackground') ||
          decoded.toLowerCase().contains('white_background')) { break; }
    }

    final bodyText = doc.body?.text ?? '';
    final price = _extractPrice(bodyText);

    return Glasses(
      id: 'deep_$idx',
      name: rawName,
      price: price,
      thumbnailUrl: imgUrl,
      // Set overlayAsset = product photo URL so it's used as face overlay.
      // White-background photos render correctly via BlendMode.multiply in the painter.
      overlayAsset: imgUrl,
      shape: _guessShape(rawName),
      productUrl: pageUrl.toString(),
    );
  }

  /// Collects deduplicated product-detail links from [doc].
  List<Uri> _collectProductLinks(Document doc, Uri base) {
    final seen = <String>{};
    final out = <Uri>[];
    for (final a in doc.querySelectorAll('a[href]')) {
      final href = a.attributes['href'] ?? '';
      if (!_productPathPatterns.any((p) => href.contains(p))) continue;
      final uri = base.resolve(href);
      final key = uri.path;
      if (seen.add(key)) out.add(uri);
      if (out.length >= 40) break; // collect more than limit for dedup safety
    }
    return out;
  }

  // ---------- helpers ----------

  /// Decodes a Next.js `/_next/image?url=ENCODED` src into the real URL.
  /// Returns null if the src is not in that format.
  String? _decodeNextImageSrc(String src) {
    if (!src.contains('/_next/image')) return null;
    final uri = Uri.tryParse(src);
    if (uri == null) return null;
    final encoded = uri.queryParameters['url'];
    if (encoded == null) return null;
    final decoded = Uri.decodeComponent(encoded);
    if (decoded.startsWith('http')) return decoded;
    return null;
  }

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
    final m = RegExp(
            r'(\d[\d.,]{2,})\s*(đ|vnđ|vnd|₫|\$)',
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
    if (s.contains('.') && !s.contains(' ')) {
      return Uri.tryParse('https://$s');
    }
    return null;
  }

  Future<http.Response> _get(Uri url) => http.get(url, headers: {
        'User-Agent': 'Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 '
            '(KHTML, like Gecko) Chrome/120 Mobile Safari/537.36',
        'Accept': 'text/html,application/xhtml+xml',
      });
}
