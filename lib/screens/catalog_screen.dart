import 'package:flutter/material.dart';

import '../models/glasses.dart';
import 'tryon_screen.dart';

class CatalogScreen extends StatelessWidget {
  final List<Glasses>? glasses; // null -> dùng demo
  final String storeLabel;

  const CatalogScreen({
    super.key,
    required this.glasses,
    required this.storeLabel,
  });

  @override
  Widget build(BuildContext context) {
    final items = glasses ?? kDemoGlasses;
    return Scaffold(
      appBar: AppBar(title: Text(storeLabel)),
      body: items.isEmpty
          ? const Center(child: Text('Không có mẫu kính nào.'))
          : GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.78,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
              ),
              itemCount: items.length,
              itemBuilder: (context, i) =>
                  _GlassesCard(glasses: items[i], catalog: items),
            ),
    );
  }
}

class _GlassesCard extends StatelessWidget {
  final Glasses glasses;
  final List<Glasses> catalog;
  const _GlassesCard({required this.glasses, required this.catalog});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) =>
              TryOnScreen(initialGlasses: glasses, catalog: catalog),
        )),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Container(
                color: Colors.grey.shade100,
                child: glasses.thumbnailUrl != null
                    ? Image.network(
                        glasses.thumbnailUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            _placeholder(glasses),
                        loadingBuilder: (c, w, p) =>
                            p == null ? w : _placeholder(glasses),
                      )
                    : _placeholder(glasses),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(glasses.name,
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(glasses.price ?? '',
                      style: TextStyle(color: Colors.grey.shade700)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              child: FilledButton.tonalIcon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        TryOnScreen(initialGlasses: glasses, catalog: catalog),
                  ),
                ),
                icon: const Icon(Icons.camera_alt_outlined, size: 18),
                label: const Text('Thử ngay'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder(Glasses g) {
    return Center(
      child: Icon(Icons.remove_red_eye_outlined,
          size: 48, color: g.frameColor),
    );
  }
}
