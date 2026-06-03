import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// V1 Terminal — cyan+green, mono-heavy, pure black bg
class TT {
  static const bg      = Color(0xFF0A0A0A);
  static const surface = Color(0xFF111111);
  static const line    = Color(0xFF1F1F1F);
  static const text    = Color(0xFFE8E8E8);
  static const muted   = Color(0xFF7A7A7A);
  static const accent  = Color(0xFF00D4FF);
  static const red     = Color(0xFFFF4D4D);
  static const orange  = Color(0xFFFF8A3D);
  static const yellow  = Color(0xFFFFB800);
  static const green   = Color(0xFF22C55E);
  static const blue    = Color(0xFF5B9DFF);

  static Color sevColor(String level) {
    switch (level) {
      case 'CRIT': return red;
      case 'HIGH': return orange;
      case 'MED':  return yellow;
      case 'LOW':  return green;
      default:     return muted;
    }
  }

  static TextStyle mono({
    double size = 10,
    FontWeight weight = FontWeight.w400,
    Color color = const Color(0xFF7A7A7A),
    double letterSpacing = 0.5,
    double? height,
  }) => GoogleFonts.jetBrainsMono(
    fontSize: size, fontWeight: weight,
    color: color, letterSpacing: letterSpacing, height: height,
  );

  static TextStyle sans({
    double size = 14,
    FontWeight weight = FontWeight.w400,
    Color color = const Color(0xFFE8E8E8),
    double? height,
    double letterSpacing = 0,
  }) => GoogleFonts.inter(
    fontSize: size, fontWeight: weight,
    color: color, height: height, letterSpacing: letterSpacing,
  );
}
