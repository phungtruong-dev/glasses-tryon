import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../services/store_scraper.dart';
import 'capture_for_pd_screen.dart';
import 'catalog_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _controller = TextEditingController();
  final _scraper = StoreScraper();
  bool _loading = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _scan() async {
    setState(() => _loading = true);
    final result = await _scraper.fetchGlasses(_controller.text);
    if (!mounted) return;
    setState(() => _loading = false);

    if (result.message.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message)),
      );
    }
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => CatalogScreen(
        glasses: result.glasses,
        storeLabel: _controller.text.trim().isEmpty
            ? 'Catalog mẫu'
            : _controller.text.trim(),
      ),
    ));
  }

  Future<void> _connectBackend() async {
    final urlCtrl = TextEditingController(text: 'http://10.0.2.2:8000');
    final storeCtrl = TextEditingController(text: 'demo');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Kết nối backend cửa hàng'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: urlCtrl,
              decoration: const InputDecoration(
                  labelText: 'Base URL', hintText: 'http://IP:8000'),
            ),
            TextField(
              controller: storeCtrl,
              decoration: const InputDecoration(labelText: 'Store ID'),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Huỷ')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Tải')),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    setState(() => _loading = true);
    try {
      final items = await ApiService(urlCtrl.text.trim())
          .fetchStoreProducts(storeCtrl.text.trim());
      if (!mounted) return;
      setState(() => _loading = false);
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => CatalogScreen(
            glasses: items, storeLabel: 'Cửa hàng: ${storeCtrl.text.trim()}'),
      ));
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Lỗi backend: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              const Icon(Icons.remove_red_eye_outlined, size: 72),
              const SizedBox(height: 16),
              Text('Thử Kính AR',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 8),
              Text(
                'Nhập link cửa hàng để quét mẫu kính,\nrồi thử trực tiếp lên khuôn mặt bằng camera.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _controller,
                keyboardType: TextInputType.url,
                decoration: const InputDecoration(
                  labelText: 'Link cửa hàng hoặc tên cửa hàng',
                  hintText: 'vd: https://shop.com/kinh-mat',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.store_outlined),
                ),
                onSubmitted: (_) => _loading ? null : _scan(),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _loading ? null : _scan,
                icon: _loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.search),
                label: Text(_loading ? 'Đang quét…' : 'Quét cửa hàng'),
                style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16)),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _loading
                    ? null
                    : () => Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => const CatalogScreen(
                            glasses: null, // dùng demo
                            storeLabel: 'Catalog mẫu',
                          ),
                        )),
                icon: const Icon(Icons.collections_outlined),
                label: const Text('Dùng catalog mẫu để thử ngay'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _loading ? null : _connectBackend,
                icon: const Icon(Icons.cloud_outlined),
                label: const Text('Kết nối backend cửa hàng'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _loading
                    ? null
                    : () => Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => const CaptureForPdScreen(),
                        )),
                icon: const Icon(Icons.straighten),
                label: const Text('Đo PD & gợi ý size gọng'),
              ),
              const Spacer(),
              Text(
                'Mẹo: dán link trang DANH MỤC hoặc CHI TIẾT sản phẩm kính để quét '
                'chính xác nhất.',
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
