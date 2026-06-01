import 'package:flutter/material.dart';

import '../main.dart' show AppState, SavedLook;
import '../models/glasses.dart';
import '../theme/lumen_theme.dart';
import '../widgets/frame_painter.dart';
import '../widgets/lumen_components.dart';
import 'product_screen.dart';

class SavedScreen extends StatefulWidget {
  const SavedScreen({super.key});

  @override
  State<SavedScreen> createState() => _SavedScreenState();
}

class _SavedScreenState extends State<SavedScreen> {
  bool _showLooks = false;

  @override
  Widget build(BuildContext context) {
    final appState = AppState.of(context);
    final favItems = kCatalog.where((f) => appState.saved.contains(f.id)).toList();
    final looks = appState.looks;

    return Column(children: [
      LumenNavBar(title: 'Saved', subtitle: 'Đã lưu'),
      // Tabs
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 22),
        child: Row(children: [
          _Tab(label: 'Wishlist', vn: 'Yêu thích', count: favItems.length,
            active: !_showLooks, onTap: () => setState(() => _showLooks = false)),
          const SizedBox(width: 24),
          _Tab(label: 'My Looks', vn: 'Ảnh thử', count: looks.length,
            active: _showLooks, onTap: () => setState(() => _showLooks = true)),
        ]),
      ),
      const Divider(height: 1, color: LC.line),
      Expanded(
        child: !_showLooks
          ? _WishlistTab(items: favItems)
          : _LooksTab(looks: looks),
      ),
    ]);
  }
}

class _Tab extends StatelessWidget {
  final String label;
  final String vn;
  final int count;
  final bool active;
  final VoidCallback onTap;
  const _Tab({required this.label, required this.vn, required this.count, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(
        color: active ? LC.accent : Colors.transparent, width: 2))),
      child: Row(children: [
        Text(label, style: LT.serif(21, color: active ? LC.ink : LC.inkFaint)),
        const SizedBox(width: 6),
        Text('$count', style: LT.sans(11, color: LC.inkFaint, w: FontWeight.w600)),
      ]),
    ),
  );
}

class _WishlistTab extends StatelessWidget {
  final List<Glasses> items;
  const _WishlistTab({required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return _Empty(icon: Icons.favorite_border, text: 'No saved frames yet', vn: 'Chưa có gọng kính nào');
    final appState = AppState.of(context);
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, crossAxisSpacing: 14, mainAxisSpacing: 14, childAspectRatio: 0.78),
      itemCount: items.length,
      itemBuilder: (_, i) {
        final f = items[i];
        return GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductScreen(item: f))),
          child: Container(
            decoration: BoxDecoration(color: LC.card, borderRadius: BorderRadius.circular(14), border: Border.all(color: LC.lineSoft)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                  child: Stack(children: [
                    FrameThumb(item: f, height: double.infinity, bg: LC.paper2),
                    Positioned(top: 8, right: 8,
                      child: GestureDetector(
                        onTap: () => appState.toggleSave(f.id),
                        child: Container(width: 30, height: 30,
                          decoration: const BoxDecoration(color: Color(0xE6FBF9F4), shape: BoxShape.circle),
                          child: const Icon(Icons.favorite, size: 16, color: LC.oxblood)),
                      )),
                  ]),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(f.name, style: LT.serif(17, color: LC.ink)),
                  const SizedBox(height: 4),
                  Text(f.formatPrice(), style: LT.sans(12.5, w: FontWeight.w700, color: LC.accentDeep)),
                ]),
              ),
            ]),
          ),
        );
      },
    );
  }
}

class _LooksTab extends StatelessWidget {
  final List<SavedLook> looks;
  const _LooksTab({required this.looks});

  @override
  Widget build(BuildContext context) {
    if (looks.isEmpty) return _Empty(icon: Icons.camera_alt_outlined, text: 'No looks captured yet', vn: 'Chưa có ảnh thử kính');
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 0.75),
      itemCount: looks.length,
      itemBuilder: (_, i) {
        final lk = looks[i];
        final cw = kColorways[lk.colorId] ?? kColorways['obsidian']!;
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
              colors: [Color(0xFF2B2620), Color(0xFF15120D)]),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Stack(children: [
            Center(child: FractionallySizedBox(
              widthFactor: 0.62,
              child: FrameWidget(shape: lk.item.shape, frameColor: cw.hex, lensColor: cw.lens, temples: false),
            )),
            Positioned(bottom: 8, left: 8,
              child: Text(lk.item.name, style: LT.sans(11, color: LC.onNoir, w: FontWeight.w600))),
          ]),
        );
      },
    );
  }
}

class _Empty extends StatelessWidget {
  final IconData icon;
  final String text;
  final String vn;
  const _Empty({required this.icon, required this.text, required this.vn});

  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 64, height: 64, decoration: const BoxDecoration(color: LC.paper2, shape: BoxShape.circle),
        child: Icon(icon, size: 28, color: LC.inkFaint)),
      const SizedBox(height: 12),
      Text(text, style: LT.serif(20, color: LC.inkSoft)),
      Text(vn, style: LT.sans(11, color: LC.inkFaint, w: FontWeight.w500)),
    ]),
  );
}
