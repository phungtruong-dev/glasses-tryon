import 'package:flutter/material.dart';

import '../models/glasses.dart';
import '../theme/lumen_theme.dart';
import '../widgets/lumen_components.dart';
import 'face_shape_screen.dart';
import 'pd_screen.dart';
import 'product_screen.dart';
import 'compare_screen.dart';

class HomeScreen extends StatelessWidget {
  final ValueChanged<int>? onTabChange;
  const HomeScreen({super.key, this.onTabChange});

  @override
  Widget build(BuildContext context) {
    final curated = kCatalog.where((f) => f.tag == 'Bestseller' || f.tag == 'New').take(6).toList();
    return SingleChildScrollView(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: 8),
        _brandBar(context),
        _editorialHero(context),
        _quickTools(context),
        _curatedSection(context, curated),
        _storeScan(context),
        const SizedBox(height: 24),
      ]),
    );
  }

  Widget _brandBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(children: [
        Text('LUMEN', style: LT.serif(22, w: FontWeight.w600, color: LC.ink).copyWith(letterSpacing: 0.16 * 22)),
        const Spacer(),
        GestureDetector(
          onTap: () => onTabChange?.call(3),
          child: Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: LC.card, shape: BoxShape.circle, border: Border.all(color: LC.line)),
            child: const Icon(Icons.bookmark_border_outlined, size: 19, color: LC.ink),
          ),
        ),
      ]),
    );
  }

  Widget _editorialHero(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Eyebrow('Maison · AR Eyewear Atelier'),
        const SizedBox(height: 8),
        RichText(text: TextSpan(children: [
          TextSpan(text: 'See yourself\nin ', style: LT.serif(46, w: FontWeight.w600, color: LC.ink).copyWith(height: 0.96)),
          TextSpan(text: 'every', style: LT.serif(46, w: FontWeight.w600, color: LC.accent, style: FontStyle.italic).copyWith(height: 0.96)),
          TextSpan(text: ' frame', style: LT.serif(46, w: FontWeight.w600, color: LC.ink).copyWith(height: 0.96)),
        ])),
        const SizedBox(height: 12),
        RichText(text: TextSpan(children: [
          TextSpan(text: 'Try on luxury eyewear in real time, find your face shape, and measure your fit — ', style: LT.sans(13.5, color: LC.inkSoft).copyWith(height: 1.5)),
          TextSpan(text: 'Thử kính ngay trên gương mặt bạn.', style: LT.sans(13.5, color: LC.inkFaint, w: FontWeight.w500).copyWith(height: 1.5)),
        ])),
        const SizedBox(height: 18),
        Row(children: [
          PillBtn('Start try-on', icon: Icons.camera_alt_outlined, onTap: () => onTabChange?.call(2)),
          const SizedBox(width: 10),
          PillBtn('Browse', variant: PillVariant.outline, onTap: () => onTabChange?.call(1)),
        ]),
      ]),
    );
  }

  Widget _quickTools(BuildContext context) {
    final tools = [
      (Icons.auto_awesome_outlined, 'Face shape', 'Dáng mặt', () => Navigator.push(context, _route(const FaceShapeScreen()))),
      (Icons.straighten_outlined,   'Measure PD', 'Đo PD',    () => Navigator.push(context, _route(const PdScreen()))),
      (Icons.compare_outlined,      'Compare',    'So sánh',  () => Navigator.push(context, _route(const CompareScreen()))),
    ];
    return Padding(
      padding: const EdgeInsets.only(top: 22, bottom: 4),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(children: tools.map((t) => _QuickTool(icon: t.$1, label: t.$2, vn: t.$3, onTap: t.$4)).toList()),
      ),
    );
  }

  Widget _curatedSection(BuildContext context, List<Glasses> items) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 26, 20, 12),
        child: SectionHeader(
          title: 'Curated for you',
          vn: 'Gợi ý dành riêng cho bạn',
          actionLabel: 'All',
          onAction: () => onTabChange?.call(1),
        ),
      ),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(children: items.map((f) => _CuratedCard(item: f)).toList()),
      ),
    ]);
  }

  Widget _storeScan(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 26, 20, 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Shop any store', style: LT.serif(24, color: LC.ink)),
        const SizedBox(height: 2),
        Text('Quét mẫu kính từ link cửa hàng bất kỳ', style: LT.sans(11, color: LC.inkFaint, w: FontWeight.w500)),
        const SizedBox(height: 14),
        Container(
          decoration: BoxDecoration(color: LC.card, borderRadius: BorderRadius.circular(14), border: Border.all(color: LC.line)),
          padding: const EdgeInsets.all(14),
          child: Column(children: [
            Container(
              decoration: BoxDecoration(color: LC.paper2, borderRadius: BorderRadius.circular(999)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              child: Row(children: [
                const Icon(Icons.link_outlined, size: 18, color: LC.inkFaint),
                const SizedBox(width: 10),
                Expanded(child: Text('shop.com/kinh-mat…', style: LT.sans(13, color: LC.inkFaint))),
                GestureDetector(
                  onTap: () => onTabChange?.call(1),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(color: LC.ink, borderRadius: BorderRadius.circular(999)),
                    child: Text('Scan', style: LT.sans(12.5, w: FontWeight.w600, color: LC.paper)),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 12),
            Row(children: [
              _StoreAction(Icons.store_outlined, 'Connect a store', () => onTabChange?.call(1)),
              const SizedBox(width: 16),
              _StoreAction(Icons.grid_view_outlined, 'Sample catalog', () => onTabChange?.call(1)),
            ]),
          ]),
        ),
      ]),
    );
  }

  static Route _route(Widget screen) => MaterialPageRoute(builder: (_) => screen);
}

class _QuickTool extends StatelessWidget {
  final IconData icon;
  final String label;
  final String vn;
  final VoidCallback onTap;
  const _QuickTool({required this.icon, required this.label, required this.vn, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      decoration: BoxDecoration(color: LC.card, borderRadius: BorderRadius.circular(999), border: Border.all(color: LC.line)),
      child: Row(children: [
        Icon(icon, size: 18, color: LC.accent),
        const SizedBox(width: 9),
        Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Text(label, style: LT.sans(13, w: FontWeight.w600, color: LC.ink)),
          Text(vn, style: LT.sans(10, color: LC.inkFaint)),
        ]),
      ]),
    ),
  );
}

class _CuratedCard extends StatelessWidget {
  final Glasses item;
  const _CuratedCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductScreen(item: item))),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.64,
        margin: const EdgeInsets.only(right: 14),
        decoration: BoxDecoration(color: LC.card, borderRadius: BorderRadius.circular(22), border: Border.all(color: LC.lineSoft)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
            child: Stack(children: [
              FrameThumb(item: item, height: 130, bg: LC.paper2),
              if (item.tag.isNotEmpty) Positioned(top: 10, left: 10, child: TagBadge(item.tag)),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(item.name, style: LT.serif(19, color: LC.ink)),
              const SizedBox(height: 6),
              Row(children: [
                Text(item.formatPrice(), style: LT.sans(13, w: FontWeight.w600, color: LC.accentDeep)),
                const Spacer(),
                ColorDots(colors: item.colors.take(3).toList(), size: 13),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _StoreAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _StoreAction(this.icon, this.label, this.onTap);

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Row(children: [
      Icon(icon, size: 16, color: LC.accent),
      const SizedBox(width: 7),
      Text(label, style: LT.sans(12.5, w: FontWeight.w600, color: LC.inkSoft)),
    ]),
  );
}
