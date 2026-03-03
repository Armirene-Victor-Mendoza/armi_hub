import 'package:flutter/material.dart';

class BrandColors {
  static const Color mint = Color(0xFF19E3CD);
  static const Color mintSoft = Color(0xFFE9FFFB);
  static const Color dark = Color(0xFF10141B);
  static const Color darkSoft = Color(0xFF1D2430);
  static const Color bg = Color(0xFFF2F5F8);
  static const Color card = Colors.white;

  static const Gradient topGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[Color(0xFF10141B), Color(0xFF1D2430)],
  );
}
