import 'package:flutter/material.dart';

import '../main.dart' show AppState;
import '../models/glasses.dart';
import '../theme/lumen_theme.dart';
import '../widgets/lumen_components.dart';
import 'product_screen.dart';

const _shapes = [
  (FrameShape.round,      'Round',     'Tròn'),
  (FrameShape.catEye,     'Cat-Eye',   'Mắt mèo'),
  (FrameShape.rectangle,  'Rect',      'Chữ nhật'),
  (FrameShape.aviator,    'Aviator',   'Phi công'),
  (FrameShape.browline,   'Browline',  'Browline'),
  (FrameShape.geometric,  'Geometric', 'Hình học'),
];

class CatalogScreen extends StatefulWidget {
  final List<Glasses>? glasses;
  final String? storeLabel;

  const CatalogScreen({super.key, this.glasses, this.storeLabel});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  FrameShape? _shape;
  String _query = '';
  String _sort = 'featured';
  int _maxPrice = 700000;
  bool _showFilter = false;

  List<Glasses> get _items {
    final source = widget.glasses ?? kCatalog;
    var r = source.where((f) =>
      (_shape == null || f.shape == _shape) &&
      f.price <= _maxPrice &&
      (_query.isEmpty || f.name.toLowerCase().contains(_query.toLowerCase()))
    ).toList();
    if (_sort == 'low')  r.sort((a, b) => a.price.compareTo(b.price));
    if (_sort == 'high') r.sort((a, b) => b.price.compareTo(a.price));
    return r;
  }

  @override
  Widget build(BuildContext context) {
    final items = _items;
    return Stack(children: [
      Column(children: [
        _header(context),
        _searchBar(),
        _shapeChips(),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
          child: Align(alignment: Alignment.centerLeft,
            child: Text('${items.length} frames · ${items.length} mẫu',
              style: LT.sans(11.5, color: LC.inkFaint, w: FontWeight.w600))),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, crossAxisSpacing: 14, mainAxisSpacing: 14, childAspectRatio: 0.72),
            itemCount: items.length,
            itemBuilder: (_, i) => _CatalogCard(item: items[i]),
          ),
        ),
      ]),
      if (_showFilter) _FilterSheet(
        maxPrice: _maxPrice, sort: _sort,
        onApply: (price, sort) => setState(() { _maxPrice = price; _sort = sort; _showFilter = false; }),
        onClose: () => setState(() => _showFilter = false),
      ),
    ]);
  }

  Widget _header(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
    child: Row(children: [
      if (Navigator.canPop(context))
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(width: 40, height: 40,
            decoration: BoxDecoration(color: LC.card, shape: BoxShape.circle, border: Border.all(color: LC.line)),
            child: const Icon(Icons.chevron_left, size: 22, color: LC.ink)),
        )
      else const SizedBox(width: 40),
      Expanded(child: Column(children: [
        Text(widget.storeLabel ?? 'Collection', style: LT.serif(21, color: LC.ink)),
        Text('Bộ sưu tập', style: LT.sans(10.5, color: LC.inkFaint, w: FontWeight.w500)),
      ])),
      GestureDetector(onTap: () => setState(() => _showFilter = true),
        child: const Icon(Icons.tune_outlined, size: 22, color: LC.ink)),
    ]),
  );

  Widget _searchBar() => Padding(
    padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
    child: Container(
      decoration: BoxDecoration(color: LC.card, borderRadius: BorderRadius.circular(999), border: Border.all(color: LC.line)),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(children: [
        const Icon(Icons.search, size: 18, color: LC.inkFaint),
        const SizedBox(width: 10),
        Expanded(child: TextField(
          onChanged: (v) => setState(() => _query = v),
          decoration: const InputDecoration.collapsed(hintText: 'Search frames · Tìm kiếm'),
          style: LT.sans(14, color: LC.ink),
        )),
      ]),
    ),
  );

  Widget _shapeChips() => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
    child: Row(children: [
      LumenChip('All', active: _shape == null, onTap: () => setState(() => _shape = null)),
      const SizedBox(width: 8),
      ..._shapes.map((s) => Padding(
        padding: const EdgeInsets.only(right: 8),
        child: LumenChip(s.$2, active: _shape == s.$1, onTap: () => setState(() => _shape = _shape == s.$1 ? null : s.$1)),
      )),
    ]),
  );
}

class _CatalogCard extends StatelessWidget {
  final Glasses item;
  const _CatalogCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final appState = AppState.of(context);
    final isSaved = appState.saved.contains(item.id);
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductScreen(item: item))),
      child: Container(
        decoration: BoxDecoration(color: LC.card, borderRadius: BorderRadius.circular(14), border: Border.all(color: LC.lineSoft)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
              child: Stack(children: [
                FrameThumb(item: item, height: double.infinity, bg: LC.paper2),
                if (item.tag.isNotEmpty) Positioned(top: 8, left: 8, child: TagBadge(item.tag)),
                Positioned(top: 8, right: 8,
                  child: GestureDetector(
                    onTap: () => appState.toggleSave(item.id),
                    child: Container(width: 30, height: 30,
                      decoration: const BoxDecoration(color: Color(0xE6FBF9F4), shape: BoxShape.circle),
                      child: Icon(isSaved ? Icons.favorite : Icons.favorite_border,
                        size: 16, color: isSaved ? LC.oxblood : LC.inkSoft)),
                  )),
              ]),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(11, 10, 11, 12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(item.name, style: LT.serif(17, color: LC.ink)),
              Text('${item.material} · ${item.width}', style: LT.sans(10.5, color: LC.inkFaint)),
              const SizedBox(height: 8),
              Row(children: [
                Text(item.formatPrice(), style: LT.sans(12.5, w: FontWeight.w700, color: LC.accentDeep)),
                const Spacer(),
                ColorDots(colors: item.colors.take(3).toList(), size: 11),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _FilterSheet extends StatefulWidget {
  final int maxPrice;
  final String sort;
  final void Function(int price, String sort) onApply;
  final VoidCallback onClose;
  const _FilterSheet({required this.maxPrice, required this.sort, required this.onApply, required this.onClose});

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late int _price;
  late String _sort;

  @override
  void initState() { super.initState(); _price = widget.maxPrice; _sort = widget.sort; }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onClose,
      child: Container(
        color: Colors.black.withValues(alpha: 0.4),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: GestureDetector(
            onTap: () {},
            child: Container(
              decoration: const BoxDecoration(color: LC.paper, borderRadius: BorderRadius.vertical(top: Radius.circular(26))),
              padding: const EdgeInsets.fromLTRB(22, 10, 22, 30),
              child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                Center(child: Container(width: 38, height: 4, decoration: BoxDecoration(color: LC.line, borderRadius: BorderRadius.circular(999)))),
                const SizedBox(height: 16),
                Text('Refine', style: LT.serif(24, color: LC.ink)),
                const SizedBox(height: 20),
                const Eyebrow('Sort by · Sắp xếp'),
                const SizedBox(height: 12),
                Row(children: [
                  for (final s in [('featured', 'Featured'), ('low', 'Price ↑'), ('high', 'Price ↓')])
                    Padding(padding: const EdgeInsets.only(right: 8),
                      child: LumenChip(s.$2, active: _sort == s.$1, onTap: () => setState(() => _sort = s.$1))),
                ]),
                const SizedBox(height: 24),
                Row(children: [
                  const Eyebrow('Max price · Giá tối đa'),
                  const Spacer(),
                  Text(_fmt(_price), style: LT.sans(13, w: FontWeight.w700, color: LC.accentDeep)),
                ]),
                SliderTheme(
                  data: SliderThemeData(activeTrackColor: LC.accent, thumbColor: LC.accent,
                    inactiveTrackColor: LC.line, overlayColor: LC.accent.withValues(alpha: 0.12)),
                  child: Slider(min: 350000, max: 700000, divisions: 35,
                    value: _price.toDouble(), onChanged: (v) => setState(() => _price = v.round())),
                ),
                const SizedBox(height: 28),
                PillBtn('Show results · Xem kết quả', variant: PillVariant.ink, full: true,
                  onTap: () => widget.onApply(_price, _sort)),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  String _fmt(int v) => '${v.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}đ';
}
