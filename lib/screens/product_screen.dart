import 'package:flutter/material.dart';

import '../main.dart' show AppState, CompareEntry;
import '../models/glasses.dart';
import '../theme/lumen_theme.dart';
import '../widgets/frame_painter.dart';
import '../widgets/lumen_components.dart';
import 'compare_screen.dart';
import 'tryon_screen.dart';

class ProductScreen extends StatefulWidget {
  final Glasses item;
  const ProductScreen({super.key, required this.item});

  @override
  State<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  late String _colorId;
  late String _lensId;

  @override
  void initState() {
    super.initState();
    _colorId = widget.item.colors.first;
    _lensId = 'clear';
  }

  LensOption get _lens => kLenses.firstWhere((l) => l.id == _lensId);
  Colorway get _cw => kColorways[_colorId] ?? kColorways['obsidian']!;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final appState = AppState.of(context);
    final isSaved = appState.saved.contains(item.id);

    return Scaffold(
      backgroundColor: LC.paper,
      body: SafeArea(
        child: Stack(children: [
          SingleChildScrollView(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // NavBar
              LumenNavBar(
                title: item.name, subtitle: item.material,
                onBack: () => Navigator.pop(context),
                right: GestureDetector(
                  onTap: () => appState.toggleSave(item.id),
                  child: Icon(isSaved ? Icons.favorite : Icons.favorite_border,
                    size: 22, color: isSaved ? LC.oxblood : LC.ink),
                ),
              ),
              // Frame hero
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const RadialGradient(colors: [LC.card, LC.paper2], radius: 1.2),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: LC.lineSoft),
                  ),
                  padding: const EdgeInsets.fromLTRB(20, 34, 20, 26),
                  child: Stack(alignment: Alignment.center, children: [
                    FractionallySizedBox(
                      widthFactor: 0.84,
                      child: FrameWidget(
                        shape: item.shape,
                        frameColor: _cw.hex,
                        lensColor: _lens.tint ?? _cw.lens,
                        lensOpacity: _lens.opacity,
                      ),
                    ),
                    if (item.tag.isNotEmpty) Positioned(top: -20, left: 0, child: TagBadge(item.tag)),
                  ]),
                ),
              ),
              // Info row
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 20, 22, 0),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(item.name, style: LT.serif(32, color: LC.ink)),
                    Text('${item.material} · ${item.materialVn} · ${item.width}',
                      style: LT.sans(12, color: LC.inkFaint)),
                  ])),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text(item.formatPrice(), style: LT.serif(26, color: LC.accentDeep)),
                    Text('\$${item.usd}', style: LT.sans(11, color: LC.inkFaint)),
                  ]),
                ]),
              ),
              // Color picker
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 22, 22, 0),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    const Eyebrow('Colour · Màu'),
                    const Spacer(),
                    Text('${_cw.name} · ${_cw.vn}',
                      style: LT.sans(12, w: FontWeight.w600, color: LC.ink)),
                  ]),
                  const SizedBox(height: 12),
                  ColorDots(colors: item.colors, selected: _colorId,
                    onSelect: (id) => setState(() => _colorId = id), size: 26),
                ]),
              ),
              // Lens picker
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 24, 22, 0),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Eyebrow('Lens · Tròng kính'),
                  const SizedBox(height: 12),
                  Row(children: kLenses.map((l) => Expanded(child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _lensId = l.id),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _lensId == l.id ? LC.accentTint : LC.card,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: _lensId == l.id ? LC.accent : LC.line,
                            width: _lensId == l.id ? 1.5 : 1),
                        ),
                        child: Column(children: [
                          Container(width: 22, height: 22, decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: l.tint ?? const Color(0xFFEEF1F3),
                            border: Border.all(color: Colors.black.withValues(alpha: 0.15)),
                          )),
                          const SizedBox(height: 5),
                          Text(l.name, style: LT.sans(10.5, w: FontWeight.w600, color: LC.ink)),
                          Text(l.vn, style: LT.sans(8.5, color: LC.inkFaint)),
                        ]),
                      ),
                    ),
                  ))).toList()),
                ]),
              ),
              // Face fit
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 24, 22, 0),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: LC.card, borderRadius: BorderRadius.circular(14), border: Border.all(color: LC.lineSoft)),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      const Icon(Icons.auto_awesome_outlined, size: 16, color: LC.accent),
                      const SizedBox(width: 8),
                      const Eyebrow('Flatters · Hợp với dáng mặt'),
                    ]),
                    const SizedBox(height: 10),
                    Wrap(spacing: 7, runSpacing: 7, children: item.fit.map((f) {
                      final fs = kFaceShapes[f];
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: LC.accentTint, borderRadius: BorderRadius.circular(999)),
                        child: Text('${fs?.name ?? f} · ${fs?.vn ?? ''}',
                          style: LT.sans(12, w: FontWeight.w600, color: LC.accentDeep)),
                      );
                    }).toList()),
                  ]),
                ),
              ),
              // Compare button
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 14, 22, 0),
                child: GestureDetector(
                  onTap: () {
                    AppState.of(context).addCompare(CompareEntry(item, _colorId));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${item.name} added to compare'),
                        backgroundColor: LC.ink, behavior: SnackBarBehavior.floating));
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const CompareScreen()));
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: LC.line, style: BorderStyle.solid),
                    ),
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Icon(Icons.compare_outlined, size: 18, color: LC.inkSoft),
                      const SizedBox(width: 8),
                      Text('Add to compare · Thêm vào so sánh',
                        style: LT.sans(13.5, w: FontWeight.w600, color: LC.inkSoft)),
                    ]),
                  ),
                ),
              ),
              const SizedBox(height: 100),
            ]),
          ),
          // Sticky CTA
          Positioned(
            left: 0, right: 0, bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 22),
              decoration: BoxDecoration(
                gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
                  colors: [LC.paper.withValues(alpha: 0), LC.paper]),
              ),
              child: Row(children: [
                PillBtn(isSaved ? 'Saved' : 'Save',
                  variant: PillVariant.ink, icon: Icons.bookmark_border_outlined,
                  onTap: () => AppState.of(context).toggleSave(item.id)),
                const SizedBox(width: 12),
                Expanded(child: PillBtn('Try on · Thử kính',
                  icon: Icons.camera_alt_outlined, full: true,
                  onTap: () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => TryOnScreen(initialGlasses: item.copyWith(frameColor: _cw.hex), catalog: kCatalog))))),
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}
