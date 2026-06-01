import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// LUMEN — Design Tokens
abstract class LC {
  static const paper = Color(0xFFF4F0E8);
  static const paper2 = Color(0xFFECE6DA);
  static const card = Color(0xFFFBF9F4);
  static const ink = Color(0xFF1C1A16);
  static const inkSoft = Color(0xFF5A544A);
  static const inkFaint = Color(0xFF948C7E);
  static const line = Color(0xFFDED6C7);
  static const lineSoft = Color(0xFFE8E1D4);
  static const accent = Color(0xFFA26A39);
  static const accentDeep = Color(0xFF6E4622);
  static const accentSoft = Color(0xFFEBDDC9);
  static const accentTint = Color(0xFFF3E9DA);
  static const oxblood = Color(0xFF7A3B36);
  static const noir = Color(0xFF15120D);
  static const noir2 = Color(0xFF1F1B14);
  static const onNoir = Color(0xFFF4EFE6);
  static const onNoirSoft = Color(0x9EF4EFE6);
  static const noirLine = Color(0x24FFFFFF);

  // radii
  static const rSm = Radius.circular(8);
  static const rMd = Radius.circular(14);
  static const rLg = Radius.circular(22);
  static const rXl = Radius.circular(30);
}

abstract class LT {
  // Serif — Cormorant Garamond
  static TextStyle serif(double size, {FontWeight w = FontWeight.w500, Color? color, FontStyle? style}) =>
      GoogleFonts.cormorantGaramond(fontSize: size, fontWeight: w, color: color, fontStyle: style, letterSpacing: 0.01 * size);

  // Sans — Hanken Grotesk
  static TextStyle sans(double size, {FontWeight w = FontWeight.w400, Color? color, double? letterSpacing}) =>
      GoogleFonts.hankenGrotesk(fontSize: size, fontWeight: w, color: color, letterSpacing: letterSpacing);

  // Eyebrow — all-caps label
  static TextStyle eyebrow({Color? color}) => GoogleFonts.hankenGrotesk(
        fontSize: 10.5, fontWeight: FontWeight.w600,
        letterSpacing: 0.22 * 10.5, color: color ?? LC.inkFaint,
      );
}

ThemeData buildLumenTheme() {
  final base = ThemeData.light(useMaterial3: true);
  return base.copyWith(
    scaffoldBackgroundColor: LC.paper,
    colorScheme: const ColorScheme.light(
      primary: LC.accent,
      onPrimary: Colors.white,
      secondary: LC.accentDeep,
      surface: LC.paper,
      onSurface: LC.ink,
    ),
    textTheme: GoogleFonts.hankenGroteskTextTheme(base.textTheme),
    appBarTheme: AppBarTheme(
      backgroundColor: LC.paper,
      foregroundColor: LC.ink,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: LT.serif(21, color: LC.ink),
    ),
    dividerColor: LC.line,
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: LC.card,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(999),
        borderSide: const BorderSide(color: LC.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(999),
        borderSide: const BorderSide(color: LC.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(999),
        borderSide: const BorderSide(color: LC.accent),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      hintStyle: LT.sans(14, color: LC.inkFaint),
    ),
  );
}
