import 'package:flutter/material.dart';

import '../main.dart' show AppState, CompareEntry;
import '../models/glasses.dart';
import '../theme/lumen_theme.dart';
import '../widgets/frame_painter.dart';
import '../widgets/lumen_components.dart';
import 'catalog_screen.dart';

class CompareScreen extends StatelessWidget {
  const CompareScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = AppState.of(context);
    final list = appState.compareList.isEmpty ? _defaults : appState.compareList;
    final cols = list.length <= 2 ? list.length : 2;

    return Scaffold(
      backgroundColor: LC.noir,
      body: SafeArea(
        child: Column(children: [
          LumenNavBar(
            dark: true,
            title: 'Compare',
            subtitle: 'So sánh trực tiếp',
            onBack: () => Navigator.pop(context),
            right: GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CatalogScreen())),
              child: const Icon(Icons.add, size: 22, color: LC.onNoir),
            ),
          ),
          Expanded(
            child: GridView.count(
              crossAxisCount: cols,
              mainAxisSpacing: 2,
              crossAxisSpacing: 2,
              padding: EdgeInsets.zero,
              children: list.asMap().entries.map((e) => _CompareCell(
                entry: e.value,
                index: e.key,
                onRemove: () => appState.removeCompare(e.key),
              )).toList(),
            ),
          ),
          Container(
            color: LC.noir,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 22),
            child: Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${list.length} frames side by side',
                  style: LT.sans(12, color: LC.onNoirSoft)),
                Text('Thử song song nhiều mẫu',
                  style: LT.sans(10.5, color: LC.onNoirSoft)),
              ])),
              PillBtn('Get votes', variant: PillVariant.outline, dark: true, icon: Icons.share_outlined),
            ]),
          ),
        ]),
      ),
    );
  }

  static final List<CompareEntry> _defaults = [
    CompareEntry(kCatalog[0], kCatalog[0].colors[0]),
    CompareEntry(kCatalog[2], kCatalog[2].colors[0]),
  ];
}

class _CompareCell extends StatelessWidget {
  final CompareEntry entry;
  final int index;
  final VoidCallback onRemove;

  const _CompareCell({required this.entry, required this.index, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final cw = kColorways[entry.colorId] ?? kColorways['obsidian']!;
    return Container(
      color: const Color(0xFF0F0D09),
      child: Stack(children: [
        // Dark portrait silhouette
        Container(
          decoration: const BoxDecoration(
            gradient: RadialGradient(center: Alignment(0, -0.3), radius: 1,
              colors: [Color(0xFF322D23), Color(0xFF1C1912), Color(0xFF0F0D09)]),
          ),
        ),
        // Frame overlay centered on face area
        Positioned(
          left: 0, right: 0,
          top: 0, bottom: 0,
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const SizedBox(height: 8),
            FractionallySizedBox(
              widthFactor: 0.72,
              child: FrameWidget(
                shape: entry.item.shape,
                frameColor: cw.hex,
                lensColor: cw.lens,
                lensOpacity: 0.3,
                temples: false,
              ),
            ),
          ]),
        ),
        // Info overlay
        Positioned(
          top: 10, left: 10, right: 10,
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(entry.item.name, style: LT.serif(19, color: LC.onNoir)),
              Text('${cw.name} · ${entry.item.formatPrice()}',
                style: LT.sans(10.5, color: LC.onNoirSoft)),
            ])),
            GestureDetector(
              onTap: onRemove,
              child: Container(
                width: 26, height: 26,
                decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.4), shape: BoxShape.circle),
                child: const Icon(Icons.close, size: 15, color: Colors.white),
              ),
            ),
          ]),
        ),
        // Color dots at bottom
        Positioned(
          bottom: 10, left: 10,
          child: ColorDots(colors: entry.item.colors.take(4).toList(), selected: entry.colorId, size: 13),
        ),
      ]),
    );
  }
}
