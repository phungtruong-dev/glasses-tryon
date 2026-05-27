import 'dart:ui';

/// Hình dạng gọng kính dùng cho chế độ vẽ vector (procedural).
/// Khi scrape web không lấy được ảnh tách nền đẹp, ta vẽ kính bằng vector
/// để try-on luôn hiển thị chuẩn.
enum FrameShape { rectangle, round, catEye, aviator }

/// Một mẫu kính trong catalog của cửa hàng.
class Glasses {
  final String id;
  final String name;
  final String? price;

  /// Ảnh sản phẩm lấy từ web cửa hàng (có thể là ảnh người mẫu đeo,
  /// dùng để hiển thị ở danh sách - KHÔNG nhất thiết dùng để overlay).
  final String? thumbnailUrl;

  /// Ảnh PNG kính đã tách nền, căn thẳng, dùng để overlay lên mặt.
  /// Có thể là URL hoặc asset. Nếu null -> dùng vẽ vector theo [shape]+[color].
  final String? overlayAsset;

  /// Cấu hình cho chế độ vẽ vector.
  final FrameShape shape;
  final Color frameColor;

  /// Link sản phẩm gốc trên web (để mở chi tiết).
  final String? productUrl;

  const Glasses({
    required this.id,
    required this.name,
    this.price,
    this.thumbnailUrl,
    this.overlayAsset,
    this.shape = FrameShape.rectangle,
    this.frameColor = const Color(0xFF222222),
    this.productUrl,
  });

  Glasses copyWith({FrameShape? shape, Color? frameColor}) => Glasses(
        id: id,
        name: name,
        price: price,
        thumbnailUrl: thumbnailUrl,
        overlayAsset: overlayAsset,
        shape: shape ?? this.shape,
        frameColor: frameColor ?? this.frameColor,
        productUrl: productUrl,
      );
}

/// Catalog mẫu - dùng làm fallback khi scrape thất bại,
/// và để demo phần AR ngay lập tức.
const List<Glasses> kDemoGlasses = [
  Glasses(
    id: 'demo_1',
    name: 'Classic Rectangle',
    price: '350.000đ',
    shape: FrameShape.rectangle,
    frameColor: Color(0xFF1A1A1A),
  ),
  Glasses(
    id: 'demo_2',
    name: 'Round Retro',
    price: '420.000đ',
    shape: FrameShape.round,
    frameColor: Color(0xFF6B4226),
  ),
  Glasses(
    id: 'demo_3',
    name: 'Cat Eye Lady',
    price: '480.000đ',
    shape: FrameShape.catEye,
    frameColor: Color(0xFFB23A48),
  ),
  Glasses(
    id: 'demo_4',
    name: 'Aviator Gold',
    price: '590.000đ',
    shape: FrameShape.aviator,
    frameColor: Color(0xFFC9A227),
  ),
  Glasses(
    id: 'demo_5',
    name: 'Slim Blue',
    price: '390.000đ',
    shape: FrameShape.rectangle,
    frameColor: Color(0xFF274690),
  ),
];
