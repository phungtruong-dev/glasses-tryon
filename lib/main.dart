import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import 'models/glasses.dart';
import 'theme/lumen_theme.dart';
import 'screens/home_screen.dart';
import 'screens/catalog_screen.dart';
import 'screens/saved_screen.dart';
import 'screens/tryon_screen.dart';

List<CameraDescription> cameras = [];

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!Platform.isMacOS) {
    try { cameras = await availableCameras(); } catch (_) {}
  }
  runApp(const LumenApp());
}

// Global app state passed down via InheritedWidget
class AppState extends InheritedWidget {
  final Set<String> saved;
  final List<SavedLook> looks;
  final List<CompareEntry> compareList;
  final void Function(String id) toggleSave;
  final void Function(SavedLook look) addLook;
  final void Function(CompareEntry e) addCompare;
  final void Function(int index) removeCompare;

  const AppState({
    super.key,
    required super.child,
    required this.saved,
    required this.looks,
    required this.compareList,
    required this.toggleSave,
    required this.addLook,
    required this.addCompare,
    required this.removeCompare,
  });

  static AppState of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppState>()!;

  @override
  bool updateShouldNotify(AppState old) =>
      saved != old.saved || looks != old.looks || compareList != old.compareList;
}

class SavedLook {
  final Glasses item;
  final String colorId;
  SavedLook(this.item, this.colorId);
}

class CompareEntry {
  final Glasses item;
  final String colorId;
  CompareEntry(this.item, this.colorId);
}

// AppState must wrap MaterialApp so pushed routes (CompareScreen, etc.) can access it.
class LumenApp extends StatefulWidget {
  const LumenApp({super.key});

  @override
  State<LumenApp> createState() => _LumenAppState();
}

class _LumenAppState extends State<LumenApp> {
  int _tab = 0;
  final _saved = <String>{};
  final _looks = <SavedLook>[];
  final _compare = <CompareEntry>[];

  void _toggleSave(String id) => setState(() => _saved.contains(id) ? _saved.remove(id) : _saved.add(id));
  void _addLook(SavedLook l) => setState(() => _looks.insert(0, l));
  void _addCompare(CompareEntry e) => setState(() { if (_compare.length < 4) _compare.add(e); });
  void _removeCompare(int i) => setState(() => _compare.removeAt(i));

  @override
  Widget build(BuildContext context) {
    return AppState(
      saved: _saved,
      looks: _looks,
      compareList: _compare,
      toggleSave: _toggleSave,
      addLook: _addLook,
      addCompare: _addCompare,
      removeCompare: _removeCompare,
      child: MaterialApp(
        title: 'LUMEN',
        debugShowCheckedModeBanner: false,
        theme: buildLumenTheme(),
        home: _AppShell(
          tab: _tab,
          saved: _saved,
          onTabChange: (t) => setState(() => _tab = t),
        ),
      ),
    );
  }
}

class _AppShell extends StatelessWidget {
  final int tab;
  final Set<String> saved;
  final ValueChanged<int> onTabChange;

  const _AppShell({required this.tab, required this.saved, required this.onTabChange});

  @override
  Widget build(BuildContext context) {
    final appState = AppState.of(context);
    return Scaffold(
      backgroundColor: LC.paper,
      // Tab bar lives inside the body Column so it gets natural height constraints.
      // Using bottomNavigationBar on macOS gave the widget unconstrained height.
      body: Column(children: [
        Expanded(
          child: IndexedStack(index: tab, children: [
            HomeScreen(onTabChange: onTabChange),
            const CatalogScreen(),
            TryOnScreen(initialGlasses: kCatalog.first, catalog: kCatalog),
            const SavedScreen(),
          ]),
        ),
        _LumenTabBar(
          current: tab,
          savedCount: appState.saved.length,
          onTap: onTabChange,
        ),
      ]),
    );
  }
}

class _LumenTabBar extends StatelessWidget {
  final int current;
  final int savedCount;
  final ValueChanged<int> onTap;

  const _LumenTabBar({required this.current, required this.savedCount, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    // Stack lets the camera button float above the bar without negative margins
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        // Bar background + regular tabs
        Container(
          decoration: const BoxDecoration(
            color: LC.card,
            border: Border(top: BorderSide(color: LC.line)),
          ),
          padding: EdgeInsets.only(
            left: 8, right: 8, top: 26,
            bottom: bottomPad + 8,
          ),
          child: Row(children: [
            _tab(0, Icons.home_outlined, 'Home', 'Trang chủ'),
            _tab(1, Icons.grid_view_outlined, 'Shop', 'Cửa hàng'),
            _camTabLabel(), // label + hit area placeholder
            _savedTab(),
          ]),
        ),
        // Floating camera circle — sits above the bar top border
        Positioned(
          top: -10,
          child: GestureDetector(
            onTap: () => onTap(2),
            child: Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                color: current == 2 ? LC.ink : LC.accent,
                shape: BoxShape.circle,
                border: Border.all(color: LC.card, width: 3),
                boxShadow: [BoxShadow(
                  color: LC.accent.withValues(alpha: 0.45),
                  blurRadius: 14, offset: const Offset(0, 6))],
              ),
              child: const Icon(Icons.camera_alt_outlined, color: Colors.white, size: 22),
            ),
          ),
        ),
      ],
    );
  }

  Widget _tab(int idx, IconData icon, String label, String vn) {
    final on = current == idx;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(idx),
        behavior: HitTestBehavior.opaque,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 23, color: on ? LC.accent : LC.inkFaint),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(
            fontSize: 9.5,
            fontWeight: on ? FontWeight.w700 : FontWeight.w500,
            color: on ? LC.accent : LC.inkFaint)),
        ]),
      ),
    );
  }

  // Camera slot — icon is transparent since the floating button is the visual.
  Widget _camTabLabel() {
    final on = current == 2;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(2),
        behavior: HitTestBehavior.opaque,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.face_outlined, size: 23, color: on ? LC.accent : LC.inkFaint),
          const SizedBox(height: 4),
          Text('Try-On', style: TextStyle(
            fontSize: 9.5,
            fontWeight: on ? FontWeight.w700 : FontWeight.w500,
            color: on ? LC.accent : LC.inkFaint)),
        ]),
      ),
    );
  }

  Widget _savedTab() {
    final on = current == 3;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(3),
        behavior: HitTestBehavior.opaque,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Stack(clipBehavior: Clip.none, children: [
            Icon(on ? Icons.bookmark : Icons.bookmark_border_outlined, size: 23, color: on ? LC.accent : LC.inkFaint),
            if (savedCount > 0)
              Positioned(
                top: -4, right: -8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  constraints: const BoxConstraints(minWidth: 15, minHeight: 15),
                  decoration: const BoxDecoration(color: LC.accent, shape: BoxShape.circle),
                  child: Text('$savedCount', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.white), textAlign: TextAlign.center),
                ),
              ),
          ]),
          const SizedBox(height: 4),
          Text('Saved', style: TextStyle(fontSize: 9.5, fontWeight: on ? FontWeight.w700 : FontWeight.w500, color: on ? LC.accent : LC.inkFaint)),
        ]),
      ),
    );
  }
}
