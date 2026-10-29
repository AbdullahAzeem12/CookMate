import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// A professional, reusable CookMate 3D logo badge widget
/// designed for seamless integration across light and dark surfaces,
/// app bars, headers, and navigation sections.
class AppLogoBadge extends StatelessWidget {
  final double size;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final double? borderRadius;
  final bool showShadow;
  final bool showBorder;
  final VoidCallback? onTap;

  const AppLogoBadge({
    super.key,
    this.size = 46.0,
    this.margin,
    this.padding,
    this.borderRadius,
    this.showShadow = true,
    this.showBorder = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final radius = borderRadius ?? (size * 0.22);
    final innerPadding = padding ?? EdgeInsets.zero;

    Widget badge = Container(
      width: size,
      height: size,
      margin: margin,
      padding: innerPadding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        border: showBorder
            ? Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.16)
                    : AppColors.forestGreen.withValues(alpha: 0.12),
                width: 1.2,
              )
            : null,
        boxShadow: showShadow
            ? [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.50)
                      : AppColors.forestGreen.withValues(alpha: 0.16),
                  blurRadius: size * 0.24,
                  offset: Offset(0, size * 0.08),
                ),
                BoxShadow(
                  color: isDark
                      ? AppColors.citrusLime.withValues(alpha: 0.12)
                      : AppColors.citrusLime.withValues(alpha: 0.08),
                  blurRadius: size * 0.10,
                  offset: Offset(0, size * 0.02),
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Image.asset(
          'assets/images/app_logo.png',
          width: size,
          height: size,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
          errorBuilder: (context, error, stackTrace) {
            return Center(
              child: Icon(
                Icons.restaurant_menu_rounded,
                size: size * 0.55,
                color: isDark ? AppColors.citrusLime : AppColors.forestGreen,
              ),
            );
          },
        ),
      ),
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: badge,
      );
    }

    return badge;
  }
}

