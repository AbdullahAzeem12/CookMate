import 'dart:io';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_cached_network_image.dart';
import '../../../../shared/widgets/bounce_tap.dart';

/// Interactive Chef Avatar displaying either a local portrait file,
/// a network URL, or the chef's first initial, with camera edit badge,
/// customizable border radius, and slim glowing border.
class ChefAvatarView extends StatelessWidget {
  final String? avatarUrl;
  final String name;
  final double size;
  final double? borderRadius;
  final bool isEditable;
  final bool showVerifiedBadge;
  final VoidCallback? onTap;

  const ChefAvatarView({
    super.key,
    required this.avatarUrl,
    required this.name,
    this.size = 104,
    this.borderRadius,
    this.isEditable = false,
    this.showVerifiedBadge = false,
    this.onTap,
  });

  bool get _isLocalFile {
    if (avatarUrl == null || avatarUrl!.isEmpty) return false;
    return !avatarUrl!.startsWith('http://') && !avatarUrl!.startsWith('https://');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveRadius = borderRadius ?? (size * 0.28);
    final padding = size > 60 ? 3.0 : 2.0;
    final innerRadius = (effectiveRadius - padding).clamp(4.0, 999.0);

    Widget imageContent;

    if (avatarUrl != null && avatarUrl!.trim().isNotEmpty) {
      if (_isLocalFile) {
        final file = File(avatarUrl!);
        imageContent = Image.file(
          file,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildFallbackInitial(isDark, innerRadius),
        );
      } else {
        imageContent = AppCachedNetworkImage(
          imageUrl: avatarUrl!,
          fit: BoxFit.cover,
        );
      }
    } else {
      imageContent = _buildFallbackInitial(isDark, innerRadius);
    }

    Widget avatarWidget = Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        // Outer Glowing Gradient Halo
        Container(
          width: size,
          height: size,
          padding: EdgeInsets.all(padding),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(effectiveRadius),
            gradient: AppColors.primaryGradient,
            boxShadow: [
              BoxShadow(
                color: (isDark ? AppColors.citrusLime : AppColors.forestGreen)
                    .withValues(alpha: 0.30),
                blurRadius: size > 60 ? 18 : 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(innerRadius),
              border: Border.all(
                color: isDark ? AppColors.citrusLime : Colors.white,
                width: size > 60 ? 2.0 : 1.4,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(innerRadius),
              child: imageContent,
            ),
          ),
        ),

        // Camera edit icon or verified badge
        if (isEditable)
          Positioned(
            bottom: -2,
            right: -2,
            child: Container(
              padding: EdgeInsets.all(size > 60 ? 6 : 4),
              decoration: BoxDecoration(
                color: AppColors.citrusLime,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark ? const Color(0xFF12251F) : Colors.white,
                  width: 2.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.camera_alt_rounded,
                size: (size * 0.16).clamp(14.0, 22.0),
                color: AppColors.deepEmerald,
              ),
            ),
          )
        else if (showVerifiedBadge)
          Positioned(
            bottom: -2,
            right: -2,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.citrusLime,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark ? const Color(0xFF12251F) : Colors.white,
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.verified_rounded,
                size: 16,
                color: AppColors.deepEmerald,
              ),
            ),
          ),
      ],
    );

    if (onTap != null) {
      return BounceTap(
        onTap: onTap,
        child: avatarWidget,
      );
    }

    return avatarWidget;
  }

  Widget _buildFallbackInitial(bool isDark, double radius) {
    final cleanName = name.trim();
    if (cleanName.isEmpty || cleanName == '👨‍🍳') {
      return Container(
        color: isDark ? const Color(0xFF132821) : AppColors.forestGreen,
        child: Center(
          child: Text(
            '👨‍🍳',
            style: TextStyle(fontSize: (size * 0.44).clamp(18.0, 52.0)),
          ),
        ),
      );
    }

    final runes = cleanName.runes;
    final firstChar = runes.isNotEmpty
        ? String.fromCharCode(runes.first).toUpperCase()
        : '👨‍🍳';

    return Container(
      color: isDark ? const Color(0xFF132821) : AppColors.forestGreen,
      child: Center(
        child: Text(
          firstChar,
          style: TextStyle(
            fontSize: size * 0.40,
            fontWeight: FontWeight.w900,
            color: AppColors.citrusLime,
            letterSpacing: -0.5,
          ),
        ),
      ),
    );
  }
}
