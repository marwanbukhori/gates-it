import 'package:flutter/material.dart';

abstract final class AppColors {
  // Brand — a warm, confident set built for pet-adoption content.
  static const Color primary          = Color(0xFF3A5A40); // deep sage
  static const Color primaryContainer = Color(0xFFDAD7CD); // muted cream
  static const Color onPrimary        = Color(0xFFF5F5F1);
  static const Color secondary        = Color(0xFFB56576); // clay rose
  static const Color secondaryContainer = Color(0xFFF6E1E4);
  static const Color tertiary         = Color(0xFFE9C46A); // sunlit gold
  static const Color background       = Color(0xFFFBF9F4); // paper cream
  static const Color surface          = Color(0xFFFFFFFF);
  static const Color surfaceVariant   = Color(0xFFF1EEE7);
  static const Color outline          = Color(0xFFCFCABD);
  static const Color error            = Color(0xFFB23A48);

  // Species accents
  static const Color dogSurface       = Color(0xFFFAEDCD);
  static const Color dogAccent        = Color(0xFF8B5E3C);
  static const Color catSurface       = Color(0xFFF5E6E6);
  static const Color catAccent        = Color(0xFF9E4E5B);

  // Neutrals
  static const Color textStrong       = Color(0xFF1F2422);
  static const Color textMuted        = Color(0xFF6A6A66);
}
