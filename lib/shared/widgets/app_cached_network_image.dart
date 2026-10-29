import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Professional, resilient cached image widget for CookMate.
///
/// Features:
/// 1. High-speed disk & memory caching via [CachedNetworkImage].
/// 2. Instant offline load from disk cache when offline or intermittent connectivity.
/// 3. Resilient multi-tier fallback: Primary URL -> Backup URL -> Stylized Category Culinary Placeholder.
/// 4. Shimmer pulse loading animation.
/// 5. Never displays an empty or broken error box.
class AppCachedNetworkImage extends StatelessWidget {
  final String imageUrl;
  final String? backupUrl;
  final String category;
  final BoxFit fit;
  final double? width;
  final double? height;
  final String? heroTag;

  const AppCachedNetworkImage({
    super.key,
    required this.imageUrl,
    this.backupUrl,
    this.category = 'Quick & Easy',
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    Widget imageContent;

    final trimmedUrl = imageUrl.trim();
    if (trimmedUrl.isEmpty || !_isValidHttpUrl(trimmedUrl)) {
      imageContent = _buildBackupOrPlaceholder(context);
    } else {
      imageContent = CachedNetworkImage(
        imageUrl: trimmedUrl,
        fit: fit,
        width: width ?? double.infinity,
        height: height ?? double.infinity,
        fadeInDuration: const Duration(milliseconds: 250),
        fadeOutDuration: const Duration(milliseconds: 200),
        placeholder: (context, url) => _buildShimmerPlaceholder(),
        errorWidget: (context, url, error) => _buildBackupOrPlaceholder(context),
      );
    }

    if (heroTag != null && heroTag!.isNotEmpty) {
      return Hero(
        tag: heroTag!,
        child: imageContent,
      );
    }

    return imageContent;
  }

  bool _isValidHttpUrl(String url) {
    final uri = Uri.tryParse(url);
    return uri != null &&
        uri.hasScheme &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.hasAuthority;
  }

  Widget _buildBackupOrPlaceholder(BuildContext context) {
    final trimmedBackup = backupUrl?.trim();
    if (trimmedBackup != null &&
        trimmedBackup.isNotEmpty &&
        _isValidHttpUrl(trimmedBackup) &&
        trimmedBackup != imageUrl.trim()) {
      return CachedNetworkImage(
        imageUrl: trimmedBackup,
        fit: fit,
        width: width ?? double.infinity,
        height: height ?? double.infinity,
        fadeInDuration: const Duration(milliseconds: 200),
        placeholder: (context, url) => _buildShimmerPlaceholder(),
        errorWidget: (context, url, error) => _buildCategoryPlaceholder(),
      );
    }

    return _buildCategoryPlaceholder();
  }

  Widget _buildShimmerPlaceholder() {
    return Container(
      width: width ?? double.infinity,
      height: height ?? double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF1B382D),
            Color(0xFF274D3F),
            Color(0xFF1B382D),
          ],
          stops: [0.1, 0.5, 0.9],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(
              AppColors.citrusLime.withValues(alpha: 0.6),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryPlaceholder() {
    final config = _getCategoryTheme(category);

    return Container(
      width: width ?? double.infinity,
      height: height ?? double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: config.gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                config.icon,
                size: 32,
                color: config.accentColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              category,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  _CategoryTheme _getCategoryTheme(String cat) {
    switch (cat.toLowerCase()) {
      case 'desserts':
        return const _CategoryTheme(
          gradientColors: [Color(0xFF3E1B24), Color(0xFF6B2B38)],
          icon: Icons.cake_rounded,
          accentColor: AppColors.softCoral,
        );
      case 'healthy meals':
        return const _CategoryTheme(
          gradientColors: [Color(0xFF123524), Color(0xFF1F523B)],
          icon: Icons.eco_rounded,
          accentColor: AppColors.citrusLime,
        );
      case 'quick & easy':
      default:
        return const _CategoryTheme(
          gradientColors: [Color(0xFF173D31), Color(0xFF2C5547)],
          icon: Icons.restaurant_menu_rounded,
          accentColor: AppColors.citrusLime,
        );
    }
  }
}

class _CategoryTheme {
  final List<Color> gradientColors;
  final IconData icon;
  final Color accentColor;

  const _CategoryTheme({
    required this.gradientColors,
    required this.icon,
    required this.accentColor,
  });
}
