import 'package:flutter/material.dart';

import '../models/glasses.dart';

/// Horizontal scrollable strip for picking a glasses model.
/// Used by both TryOnScreen (mobile) and MacOSArBody (macOS).
class GlassesSelector extends StatelessWidget {
  final List<Glasses> options;
  final String selectedId;
  final ValueChanged<Glasses> onSelect;

  const GlassesSelector({
    super.key,
    required this.options,
    required this.selectedId,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 96,
      color: Colors.black54,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        itemCount: options.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final g = options[i];
          final active = g.id == selectedId;
          return GestureDetector(
            onTap: () => onSelect(g),
            child: Container(
              width: 90,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: active ? Colors.white : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.remove_red_eye, color: g.frameColor),
                  const SizedBox(height: 4),
                  Text(
                    g.name,
                    style: const TextStyle(color: Colors.white, fontSize: 10),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
