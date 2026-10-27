import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppTheme {
  static const List<String> _primaryFontFallback = [
    'Outfit',
    'Plus Jakarta Sans',
    'Inter',
    'Segoe UI',
    'Roboto',
    'Helvetica Neue',
    'sans-serif',
  ];

  static const List<String> _serifFontFallback = [
    'Playfair Display',
    'Georgia',
    'Cambria',
    'Times New Roman',
    'serif',
  ];

  static TextTheme _buildTextTheme({required bool isDark}) {
    final textColor = isDark ? AppColors.textLight : AppColors.textDark;
    final mutedColor = isDark
        ? AppColors.textMutedDark
        : AppColors.textMutedLight;

    return TextTheme(
      displayLarge: TextStyle(
        fontFamilyFallback: _serifFontFallback,
        fontSize: 34,
        fontWeight: FontWeight.w800,
        color: textColor,
        letterSpacing: -0.8,
        height: 1.15,
      ),
      displayMedium: TextStyle(
        fontFamilyFallback: _serifFontFallback,
        fontSize: 28,
        fontWeight: FontWeight.w800,
        color: textColor,
        letterSpacing: -0.5,
        height: 1.2,
      ),
      headlineLarge: TextStyle(
        fontFamilyFallback: _primaryFontFallback,
        fontSize: 24,
        fontWeight: FontWeight.w800,
        color: textColor,
        letterSpacing: -0.3,
      ),
      headlineMedium: TextStyle(
        fontFamilyFallback: _primaryFontFallback,
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: textColor,
      ),
      headlineSmall: TextStyle(
        fontFamilyFallback: _primaryFontFallback,
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: textColor,
      ),
      titleLarge: TextStyle(
        fontFamilyFallback: _primaryFontFallback,
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: textColor,
      ),
      titleMedium: TextStyle(
        fontFamilyFallback: _primaryFontFallback,
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
      titleSmall: TextStyle(
        fontFamilyFallback: _primaryFontFallback,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
      bodyLarge: TextStyle(
        fontFamilyFallback: _primaryFontFallback,
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: textColor,
        height: 1.5,
      ),
      bodyMedium: TextStyle(
        fontFamilyFallback: _primaryFontFallback,
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: mutedColor,
        height: 1.45,
      ),
      bodySmall: TextStyle(
        fontFamilyFallback: _primaryFontFallback,
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: mutedColor,
      ),
      labelLarge: TextStyle(
        fontFamilyFallback: _primaryFontFallback,
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: textColor,
      ),
    );
  }

  static ThemeData get lightTheme {
    final textTheme = _buildTextTheme(isDark: false);

    const colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.forestGreen,
      onPrimary: Colors.white,
      primaryContainer: Color(0xFFC7E2D3),
      onPrimaryContainer: AppColors.deepEmerald,
      secondary: AppColors.citrusLime,
      onSecondary: AppColors.deepEmerald,
      secondaryContainer: Color(0xFFF0FAD2),
      onSecondaryContainer: Color(0xFF2C3E08),
      tertiary: AppColors.softCoral,
      onTertiary: Colors.white,
      tertiaryContainer: AppColors.coralLight,
      onTertiaryContainer: Color(0xFF5A1E11),
      error: Color(0xFFBA1A1A),
      onError: Colors.white,
      surface: AppColors.warmCream,
      onSurface: AppColors.textDark,
      surfaceContainerHighest: Color(0xFFE8E2D2),
      outline: Color(0xFFB8C2BC),
      outlineVariant: Color(0xFFD6DDD8),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.warmCream,
      textTheme: textTheme,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: AppColors.forestGreen),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.black.withValues(alpha: 0.04)),
        ),
        color: Colors.white,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Colors.white,
        selectedColor: AppColors.forestGreen,
        secondarySelectedColor: AppColors.citrusLime,
        labelStyle: textTheme.labelLarge?.copyWith(color: AppColors.textDark),
        secondaryLabelStyle: textTheme.labelLarge?.copyWith(
          color: AppColors.deepEmerald,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
          side: BorderSide(
            color: AppColors.forestGreen.withValues(alpha: 0.12),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.9),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.08)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: AppColors.forestGreen,
            width: 1.8,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFBA1A1A), width: 1.4),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.forestGreen,
          foregroundColor: Colors.white,
          elevation: 2,
          shadowColor: AppColors.forestGreen.withValues(alpha: 0.35),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    final textTheme = _buildTextTheme(isDark: true);

    const colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: AppColors.citrusLime,
      onPrimary: AppColors.deepEmerald,
      primaryContainer: Color(0xFF1E4336),
      onPrimaryContainer: AppColors.citrusLime,
      secondary: AppColors.secondarySage,
      onSecondary: AppColors.deepEmerald,
      secondaryContainer: Color(0xFF1A352B),
      onSecondaryContainer: Color(0xFFD0EBD8),
      tertiary: AppColors.softCoral,
      onTertiary: Color(0xFF4A160D),
      tertiaryContainer: Color(0xFF5E2215),
      onTertiaryContainer: AppColors.coralLight,
      error: Color(0xFFFFB4AB),
      onError: Color(0xFF690005),
      surface: AppColors.deepSurface,
      onSurface: AppColors.textLight,
      surfaceContainerHighest: Color(0xFF193229),
      outline: Color(0xFF385549),
      outlineVariant: Color(0xFF233B31),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.deepSurface,
      textTheme: textTheme,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: AppColors.citrusLime),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
        color: const Color(0xFF162D25),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFF162D25),
        selectedColor: AppColors.citrusLime,
        labelStyle: textTheme.labelLarge?.copyWith(color: AppColors.textLight),
        secondaryLabelStyle: textTheme.labelLarge?.copyWith(
          color: AppColors.deepEmerald,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF183027),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.citrusLime, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFFFB4AB), width: 1.4),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.citrusLime,
          foregroundColor: AppColors.deepEmerald,
          elevation: 2,
          shadowColor: Colors.black45,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
    );
  }
}
