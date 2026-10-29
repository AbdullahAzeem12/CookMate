import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import 'bounce_tap.dart';
import 'glass_card.dart';

class GlassSearchBar extends StatelessWidget {
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onFilterTap;
  final VoidCallback? onTap;
  final bool readOnly;
  final String hintText;
  final bool showFilterButton;
  final int activeFilterCount;

  const GlassSearchBar({
    super.key,
    this.controller,
    this.onChanged,
    this.onFilterTap,
    this.onTap,
    this.readOnly = false,
    this.hintText = 'What are you craving today?',
    this.showFilterButton = true,
    this.activeFilterCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GlassSurface(
      borderRadius: 24,
      blur: 16,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      backgroundColor: isDark
          ? const Color(0xFF162D25).withValues(alpha: 0.8)
          : Colors.white.withValues(alpha: 0.85),
      borderColor: isDark
          ? Colors.white.withValues(alpha: 0.12)
          : Colors.black.withValues(alpha: 0.06),
      child: Row(
        children: [
          Icon(
            Icons.search_rounded,
            color: isDark ? AppColors.citrusLime : AppColors.forestGreen,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              readOnly: readOnly,
              onTap: onTap,
              onChanged: onChanged,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: TextStyle(
                  color: isDark
                      ? AppColors.textMutedDark
                      : AppColors.textMutedLight,
                  fontSize: 15,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          if (controller != null && controller!.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.close_rounded, size: 20),
              onPressed: () {
                controller?.clear();
                onChanged?.call('');
              },
            ),
          if (showFilterButton)
            Container(
              margin: const EdgeInsets.only(left: 6),
              child: BounceTap(
                onTap: onFilterTap,
                shrinkScale: 0.88,
                child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: activeFilterCount > 0
                          ? AppColors.citrusLime
                          : (isDark
                                ? const Color(0xFF1D3A2F)
                                : const Color(0xFFE8F1EC)),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Icon(
                          Icons.tune_rounded,
                          size: 20,
                          color: activeFilterCount > 0
                              ? AppColors.deepEmerald
                              : (isDark ? Colors.white : AppColors.forestGreen),
                        ),
                        if (activeFilterCount > 0)
                          Positioned(
                            top: -4,
                            right: -4,
                            child: Container(
                              padding: const EdgeInsets.all(3),
                              decoration: const BoxDecoration(
                                color: AppColors.softCoral,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '$activeFilterCount',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
        ],
      ),
    );
  }
}
