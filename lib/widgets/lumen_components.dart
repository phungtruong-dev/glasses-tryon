import 'package:flutter/material.dart';
import '../models/glasses.dart';
import '../theme/lumen_theme.dart';
import 'frame_painter.dart';

// ── NavBar ──────────────────────────────────────────────────────────────────

class LumenNavBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final VoidCallback? onBack;
  final Widget? right;
  final bool dark;
  final bool transparent;

  const LumenNavBar({
    super.key,
    required this.title,
    this.subtitle,
    this.onBack,
    this.right,
    this.dark = false,
    this.transparent = false,
  });

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    final fg = dark ? LC.onNoir : LC.ink;
    final bg = transparent ? Colors.transparent : (dark ? LC.noir : LC.paper);
    return Container(
      color: bg,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      height: 56,
      child: Row(children: [
        if (onBack != null)
          _NavBtn(onTap: onBack!, dark: dark, child: const Icon(Icons.chevron_left, size: 22))
        else
          const SizedBox(width: 40),
        Expanded(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(title, style: LT.serif(21, color: fg), textAlign: TextAlign.center),
            if (subtitle != null)
              Text(subtitle!, style: LT.sans(10.5, color: dark ? LC.onNoirSoft : LC.inkFaint, w: FontWeight.w500), textAlign: TextAlign.center),
          ]),
        ),
        SizedBox(width: 40, child: right != null ? Align(alignment: Alignment.centerRight, child: right!) : null),
      ]),
    );
  }
}

class _NavBtn extends StatelessWidget {
  final VoidCallback onTap;
  final bool dark;
  final Widget child;
  const _NavBtn({required this.onTap, required this.dark, required this.child});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          color: dark ? Colors.white.withValues(alpha: 0.08) : LC.card,
          shape: BoxShape.circle,
          border: dark ? null : Border.all(color: LC.line),
        ),
        child: IconTheme(data: IconThemeData(color: dark ? LC.onNoir : LC.ink, size: 20), child: child),
      ),
    );
  }
}

// ── PillButton ───────────────────────────────────────────────────────────────

enum PillVariant { solid, ink, outline, soft, glass }

class PillBtn extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final PillVariant variant;
  final IconData? icon;
  final bool full;
  final bool dark;

  const PillBtn(this.label, {super.key, this.onTap, this.variant = PillVariant.solid, this.icon, this.full = false, this.dark = false});

  @override
  Widget build(BuildContext context) {
    final (bg, fg, border) = switch (variant) {
      PillVariant.solid   => (LC.accent,                         Colors.white,   null),
      PillVariant.ink     => (LC.ink,                            LC.paper,       null),
      PillVariant.outline => (Colors.transparent,                dark ? LC.onNoir : LC.ink, dark ? LC.noirLine : LC.line),
      PillVariant.soft    => (LC.accentTint,                     LC.accentDeep,  null),
      PillVariant.glass   => (Colors.white.withValues(alpha: 0.12), LC.onNoir,   Colors.white.withValues(alpha: 0.16)),
    };
    return SizedBox(
      width: full ? double.infinity : null,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(999),
            border: border != null ? Border.all(color: border) : null,
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, mainAxisSize: full ? MainAxisSize.max : MainAxisSize.min, children: [
            if (icon != null) ...[Icon(icon, size: 18, color: fg), const SizedBox(width: 8)],
            Text(label, style: LT.sans(14.5, w: FontWeight.w600, color: fg)),
          ]),
        ),
      ),
    );
  }
}

// ── Chip ─────────────────────────────────────────────────────────────────────

class LumenChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback? onTap;

  const LumenChip(this.label, {super.key, this.active = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? LC.ink : LC.card,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: active ? LC.ink : LC.line),
        ),
        child: Text(label, style: LT.sans(13, w: FontWeight.w600, color: active ? LC.paper : LC.inkSoft)),
      ),
    );
  }
}

// ── ColorDots ────────────────────────────────────────────────────────────────

class ColorDots extends StatelessWidget {
  final List<String> colors;
  final String? selected;
  final ValueChanged<String>? onSelect;
  final double size;

  const ColorDots({super.key, required this.colors, this.selected, this.onSelect, this.size = 18});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: colors.map((id) {
      final cw = kColorways[id];
      if (cw == null) return const SizedBox.shrink();
      final on = selected == id;
      return GestureDetector(
        onTap: onSelect != null ? () => onSelect!(id) : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: on ? size + 6 : size, height: on ? size + 6 : size,
          margin: const EdgeInsets.only(right: 7),
          decoration: BoxDecoration(
            color: cw.hex, shape: BoxShape.circle,
            border: on ? Border.all(color: LC.accent, width: 2) : Border.all(color: Colors.black.withValues(alpha: 0.12)),
            boxShadow: [BoxShadow(color: Colors.white.withValues(alpha: 0.3), blurRadius: 0, offset: const Offset(0, 1), spreadRadius: -1)],
          ),
        ),
      );
    }).toList());
  }
}

// ── FrameThumb ───────────────────────────────────────────────────────────────

class FrameThumb extends StatelessWidget {
  final Glasses item;
  final String? colorId;
  final double height;
  final Color? bg;

  const FrameThumb({super.key, required this.item, this.colorId, this.height = 120, this.bg});

  @override
  Widget build(BuildContext context) {
    final cw = kColorways[colorId ?? item.colors.first] ?? kColorways['obsidian']!;
    return Container(
      height: height,
      color: bg ?? LC.paper2,
      child: Center(
        child: FractionallySizedBox(
          widthFactor: 0.72,
          child: FrameWidget(
            shape: item.shape, frameColor: cw.hex, lensColor: cw.lens, lensOpacity: 0.22,
          ),
        ),
      ),
    );
  }
}

// ── Tag badge ────────────────────────────────────────────────────────────────

class TagBadge extends StatelessWidget {
  final String tag;
  const TagBadge(this.tag, {super.key});

  @override
  Widget build(BuildContext context) {
    if (tag.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: tag == 'New' ? LC.ink : LC.accent,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(tag.toUpperCase(), style: LT.sans(9.5, w: FontWeight.w700, letterSpacing: 0.08 * 9.5, color: Colors.white)),
    );
  }
}

// ── Eyebrow label ─────────────────────────────────────────────────────────────

class Eyebrow extends StatelessWidget {
  final String text;
  final bool accent;
  const Eyebrow(this.text, {super.key, this.accent = false});

  @override
  Widget build(BuildContext context) =>
      Text(text, style: LT.eyebrow(color: accent ? LC.accent : null));
}

// ── Section divider with title ────────────────────────────────────────────────

class SectionHeader extends StatelessWidget {
  final String title;
  final String? vn;
  final String? actionLabel;
  final VoidCallback? onAction;

  const SectionHeader({super.key, required this.title, this.vn, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: LT.serif(24, color: LC.ink)),
        if (vn != null) Text(vn!, style: LT.sans(11, color: LC.inkFaint, w: FontWeight.w500)),
      ])),
      if (actionLabel != null && onAction != null)
        GestureDetector(
          onTap: onAction,
          child: Row(children: [
            Text(actionLabel!, style: LT.sans(13, w: FontWeight.w600, color: LC.accent)),
            const Icon(Icons.arrow_forward, size: 15, color: LC.accent),
          ]),
        ),
    ]);
  }
}
