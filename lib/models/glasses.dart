import 'package:flutter/material.dart';

enum FrameShape { rectangle, round, catEye, aviator, browline, geometric }

// Colorway descriptor
class Colorway {
  final String id;
  final String name;
  final String vn;
  final Color hex;
  final Color lens;
  const Colorway({required this.id, required this.name, required this.vn, required this.hex, required this.lens});
}

const kColorways = <String, Colorway>{
  'obsidian':  Colorway(id: 'obsidian',  name: 'Obsidian',       vn: 'Đen',         hex: Color(0xFF23201C), lens: Color(0xFF6F7D86)),
  'tortoise':  Colorway(id: 'tortoise',  name: 'Tortoise',       vn: 'Đồi mồi',    hex: Color(0xFF7A4E27), lens: Color(0xFF8A7A52)),
  'cognac':    Colorway(id: 'cognac',    name: 'Cognac',         vn: 'Hổ phách',    hex: Color(0xFFA26A39), lens: Color(0xFFC0A06A)),
  'champagne': Colorway(id: 'champagne', name: 'Champagne Gold', vn: 'Vàng champagne', hex: Color(0xFFC9A86A), lens: Color(0xFFD8C69A)),
  'crystal':   Colorway(id: 'crystal',   name: 'Crystal',        vn: 'Trong suốt',  hex: Color(0xFFB9B2A4), lens: Color(0xFFAEB6BB)),
  'forest':    Colorway(id: 'forest',    name: 'Forest',         vn: 'Xanh rêu',    hex: Color(0xFF42513E), lens: Color(0xFF7D8A72)),
  'oxblood':   Colorway(id: 'oxblood',   name: 'Oxblood',        vn: 'Đỏ rượu',    hex: Color(0xFF6E3531), lens: Color(0xFF9A7066)),
  'slate':     Colorway(id: 'slate',     name: 'Slate Blue',     vn: 'Xanh thép',   hex: Color(0xFF3C4A5A), lens: Color(0xFF8A98A6)),
};

class FaceShapeInfo {
  final String key;
  final String name;
  final String vn;
  final String blurb;
  final List<String> bestShapes;
  const FaceShapeInfo({required this.key, required this.name, required this.vn, required this.blurb, required this.bestShapes});
}

const kFaceShapes = <String, FaceShapeInfo>{
  'oval':    FaceShapeInfo(key: 'oval',    name: 'Oval',    vn: 'Trái xoan',  blurb: 'Balanced proportions — most frames suit you.',         bestShapes: ['geometric', 'browline', 'rectangle']),
  'round':   FaceShapeInfo(key: 'round',   name: 'Round',   vn: 'Tròn',       blurb: 'Angular frames add definition and structure.',         bestShapes: ['rectangle', 'geometric', 'browline']),
  'square':  FaceShapeInfo(key: 'square',  name: 'Square',  vn: 'Vuông',      blurb: 'Soft, curved frames balance a strong jaw.',           bestShapes: ['round', 'aviator', 'catEye']),
  'heart':   FaceShapeInfo(key: 'heart',   name: 'Heart',   vn: 'Trái tim',   blurb: 'Frames wider at the bottom restore balance.',         bestShapes: ['aviator', 'round', 'catEye']),
  'diamond': FaceShapeInfo(key: 'diamond', name: 'Diamond', vn: 'Kim cương',  blurb: 'Cat-eye and oval soften the cheekbones.',            bestShapes: ['catEye', 'browline', 'round']),
};

class LensOption {
  final String id;
  final String name;
  final String vn;
  final double opacity;
  final Color? tint;
  const LensOption({required this.id, required this.name, required this.vn, required this.opacity, this.tint});
}

const kLenses = <LensOption>[
  LensOption(id: 'clear', name: 'Clear',      vn: 'Trong',    opacity: 0.16),
  LensOption(id: 'blue',  name: 'Blue-light', vn: 'Lọc xanh', opacity: 0.20, tint: Color(0xFF7C8EA0)),
  LensOption(id: 'sun',   name: 'Sun',        vn: 'Râm',      opacity: 0.55, tint: Color(0xFF3A342A)),
  LensOption(id: 'grad',  name: 'Gradient',   vn: 'Loang',    opacity: 0.42, tint: Color(0xFF5A4A3A)),
];

class Glasses {
  final String id;
  final String name;
  final String vn;
  final FrameShape shape;
  final String material;
  final String materialVn;
  final int price;
  final int usd;
  final List<String> colors;
  final List<String> fit;
  final String width; // Narrow / Medium / Wide
  final String tag;   // Bestseller / New / ''

  // Legacy fields kept for camera overlay compatibility
  final String? thumbnailUrl;
  final String? overlayAsset;
  final Color frameColor;
  final String? productUrl;

  const Glasses({
    required this.id,
    required this.name,
    this.vn = '',
    required this.shape,
    this.material = 'Acetate',
    this.materialVn = 'Acetate',
    this.price = 0,
    this.usd = 0,
    this.colors = const ['obsidian'],
    this.fit = const [],
    this.width = 'Medium',
    this.tag = '',
    this.thumbnailUrl,
    this.overlayAsset,
    this.frameColor = const Color(0xFF1C1A16),
    this.productUrl,
  });

  Glasses copyWith({FrameShape? shape, Color? frameColor, String? selectedColor}) => Glasses(
    id: id, name: name, vn: vn, shape: shape ?? this.shape,
    material: material, materialVn: materialVn, price: price, usd: usd,
    colors: colors, fit: fit, width: width, tag: tag,
    thumbnailUrl: thumbnailUrl, overlayAsset: overlayAsset,
    frameColor: frameColor ?? this.frameColor, productUrl: productUrl,
  );

  Colorway get defaultColorway => kColorways[colors.first] ?? kColorways['obsidian']!;
  String formatPrice() => '${price.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}đ';
}

const List<Glasses> kCatalog = [
  Glasses(id: 'luna',   name: 'Luna',   vn: 'Luna',   shape: FrameShape.round,      material: 'Acetate',  materialVn: 'Acetate',  price: 420000, usd: 165, colors: ['tortoise','cognac','crystal','obsidian'], fit: ['square','heart','diamond'], width: 'Medium', tag: 'Bestseller', frameColor: Color(0xFF7A4E27)),
  Glasses(id: 'noor',   name: 'Noor',   vn: 'Noor',   shape: FrameShape.catEye,     material: 'Acetate',  materialVn: 'Acetate',  price: 480000, usd: 188, colors: ['oxblood','obsidian','tortoise','champagne'], fit: ['round','oval','square'], width: 'Medium', tag: 'New',        frameColor: Color(0xFF6E3531)),
  Glasses(id: 'atlas',  name: 'Atlas',  vn: 'Atlas',  shape: FrameShape.rectangle,  material: 'Titanium', materialVn: 'Titan',    price: 590000, usd: 232, colors: ['obsidian','slate','champagne'], fit: ['round','oval','heart'],           width: 'Wide',   tag: '',           frameColor: Color(0xFF23201C)),
  Glasses(id: 'soleil', name: 'Soleil', vn: 'Soleil', shape: FrameShape.aviator,    material: 'Metal',    materialVn: 'Kim loại', price: 540000, usd: 212, colors: ['champagne','cognac','slate'], fit: ['square','heart','diamond'],         width: 'Wide',   tag: '',           frameColor: Color(0xFFC9A86A)),
  Glasses(id: 'ivy',    name: 'Ivy',    vn: 'Ivy',    shape: FrameShape.browline,   material: 'Mixed',    materialVn: 'Hỗn hợp', price: 510000, usd: 200, colors: ['tortoise','forest','obsidian'], fit: ['oval','round','diamond'],          width: 'Medium', tag: '',           frameColor: Color(0xFF7A4E27)),
  Glasses(id: 'marlo',  name: 'Marlo',  vn: 'Marlo',  shape: FrameShape.geometric,  material: 'Acetate',  materialVn: 'Acetate',  price: 460000, usd: 180, colors: ['crystal','oxblood','forest','obsidian'], fit: ['round','oval','heart'],  width: 'Medium', tag: 'New',        frameColor: Color(0xFFB9B2A4)),
  Glasses(id: 'vera',   name: 'Vera',   vn: 'Vera',   shape: FrameShape.round,      material: 'Metal',    materialVn: 'Kim loại', price: 390000, usd: 152, colors: ['champagne','cognac','obsidian'], fit: ['square','heart'],               width: 'Narrow', tag: '',           frameColor: Color(0xFFC9A86A)),
  Glasses(id: 'dune',   name: 'Dune',   vn: 'Dune',   shape: FrameShape.rectangle,  material: 'Acetate',  materialVn: 'Acetate',  price: 350000, usd: 138, colors: ['tortoise','obsidian','slate','forest'], fit: ['round','oval','heart'],   width: 'Medium', tag: 'Bestseller', frameColor: Color(0xFF7A4E27)),
  Glasses(id: 'lyric',  name: 'Lyric',  vn: 'Lyric',  shape: FrameShape.catEye,     material: 'Acetate',  materialVn: 'Acetate',  price: 470000, usd: 184, colors: ['tortoise','oxblood','crystal'], fit: ['round','oval','square'],         width: 'Narrow', tag: '',           frameColor: Color(0xFF7A4E27)),
  Glasses(id: 'orion',  name: 'Orion',  vn: 'Orion',  shape: FrameShape.aviator,    material: 'Titanium', materialVn: 'Titan',    price: 620000, usd: 244, colors: ['obsidian','champagne','slate'], fit: ['square','heart','diamond'],       width: 'Wide',   tag: '',           frameColor: Color(0xFF23201C)),
  Glasses(id: 'wren',   name: 'Wren',   vn: 'Wren',   shape: FrameShape.browline,   material: 'Acetate',  materialVn: 'Acetate',  price: 440000, usd: 172, colors: ['forest','tortoise','obsidian'], fit: ['oval','round'],                  width: 'Medium', tag: '',           frameColor: Color(0xFF42513E)),
  Glasses(id: 'echo',   name: 'Echo',   vn: 'Echo',   shape: FrameShape.geometric,  material: 'Metal',    materialVn: 'Kim loại', price: 500000, usd: 196, colors: ['champagne','slate','oxblood'], fit: ['round','oval','square'],          width: 'Wide',   tag: 'New',        frameColor: Color(0xFFC9A86A)),
];

// Legacy alias for screens that reference kDemoGlasses
List<Glasses> get kDemoGlasses => kCatalog;
