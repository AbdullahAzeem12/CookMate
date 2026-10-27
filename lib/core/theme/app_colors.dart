import 'package:flutter/material.dart';

class AppColors {
  // Brand tokens from prompt
  static const Color forestGreen = Color(0xFF173D31);
  static const Color warmCream = Color(0xFFF8F4EA);
  static const Color citrusLime = Color(0xFFD8F078);
  static const Color softCoral = Color(0xFFF18C72);
  static const Color secondarySage = Color(0xFFA8C4AD);
  static const Color deepSurface = Color(0xFF12251F);

  // Accent variations
  static const Color deepEmerald = Color(0xFF0F2B22);
  static const Color lightMint = Color(0xFFE8F5E9);
  static const Color goldenAmber = Color(0xFFFFB300);
  static const Color coralLight = Color(0xFFFFE8E4);

  // Neutral tones
  static const Color textDark = Color(0xFF1C2D27);
  static const Color textMutedLight = Color(0xFF6B7E76);
  static const Color textLight = Color(0xFFF4F8F6);
  static const Color textMutedDark = Color(0xFFA2B4AC);

  // Liquid Glass Tokens - Light Mode
  static Color glassBgLight = Colors.white.withValues(alpha: 0.68);
  static Color glassBgLightHover = Colors.white.withValues(alpha: 0.82);
  static Color glassBorderLight = Colors.white.withValues(alpha: 0.70);
  static Color glassShadowLight = const Color(0xFF173D31)
      .withValues(alpha: 0.08);

  // Liquid Glass Tokens - Dark Mode
  static Color glassBgDark = const Color(0xFF173D31).withValues(alpha: 0.55);
  static Color glassBgDarkHover = const Color(0xFF1E4C3D)
      .withValues(alpha: 0.70);
  static Color glassBorderDark = Colors.white.withValues(alpha: 0.15);
  static Color glassShadowDark = Colors.black.withValues(alpha: 0.35);

  // Shimmer colors
  static Color shimmerBase = Colors.grey.shade300;
  static Color shimmerHighlight = Colors.grey.shade100;
  static Color shimmerBaseDark = const Color(0xFF1E352C);
  static Color shimmerHighlightDark = const Color(0xFF2C4A3F);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [forestGreen, Color(0xFF225545)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [citrusLime, Color(0xFFBCE640)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient coralGradient = LinearGradient(
    colors: [softCoral, Color(0xFFE07255)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroCardOverlay = LinearGradient(
    colors: [Colors.transparent, Colors.black26, Color(0xDD0B1A15)],
    stops: [0.35, 0.65, 1.0],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
