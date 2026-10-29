import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/bounce_tap.dart';

enum AvatarSourceAction {
  camera,
  gallery,
  remove,
}

class AvatarSourceSheet extends StatelessWidget {
  final bool hasExistingAvatar;

  const AvatarSourceSheet({
    super.key,
    required this.hasExistingAvatar,
  });

  static Future<AvatarSourceAction?> show(
    BuildContext context, {
    required bool hasExistingAvatar,
  }) {
    return showModalBottomSheet<AvatarSourceAction?>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => AvatarSourceSheet(hasExistingAvatar: hasExistingAvatar),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF132821) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 44,
              height: 4.5,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.2)
                    : Colors.black.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 18),

            // Title
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.citrusLime.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Text('👨‍🍳', style: TextStyle(fontSize: 22)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Update Chef Portrait',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        ),
                      ),
                      Text(
                        'Choose camera or gallery to personalize your profile',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: isDark
                              ? AppColors.textMutedDark
                              : AppColors.textMutedLight,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Option 1: Front Camera Selfie
            _buildSourceOption(
              context: context,
              action: AvatarSourceAction.camera,
              icon: Icons.camera_front_rounded,
              iconColor: AppColors.goldenAmber,
              title: 'Take Front Camera Selfie',
              subtitle: 'Auto-crops & applies beauty radiance filter',
              isDark: isDark,
            ),
            const SizedBox(height: 10),

            // Option 2: Gallery
            _buildSourceOption(
              context: context,
              action: AvatarSourceAction.gallery,
              icon: Icons.photo_library_rounded,
              iconColor: AppColors.citrusLime,
              title: 'Choose from Photo Gallery',
              subtitle: 'Select an existing portrait from device storage',
              isDark: isDark,
            ),

            // Option 3: Remove
            if (hasExistingAvatar) ...[
              const SizedBox(height: 10),
              _buildSourceOption(
                context: context,
                action: AvatarSourceAction.remove,
                icon: Icons.delete_outline_rounded,
                iconColor: AppColors.softCoral,
                title: 'Reset to Initial Avatar',
                subtitle: 'Remove custom photo and use first letter',
                isDark: isDark,
                isDestructive: true,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSourceOption({
    required BuildContext context,
    required AvatarSourceAction action,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool isDark,
    bool isDestructive = false,
  }) {
    return BounceTap(
      onTap: () => Navigator.of(context).pop(action),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isDark
              ? (isDestructive
                  ? AppColors.softCoral.withValues(alpha: 0.12)
                  : Colors.white.withValues(alpha: 0.05))
              : (isDestructive
                  ? AppColors.softCoral.withValues(alpha: 0.08)
                  : Colors.grey.shade50),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark
                ? (isDestructive
                    ? AppColors.softCoral.withValues(alpha: 0.3)
                    : Colors.white.withValues(alpha: 0.10))
                : (isDestructive
                    ? AppColors.softCoral.withValues(alpha: 0.3)
                    : Colors.black.withValues(alpha: 0.06)),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: isDestructive ? AppColors.softCoral : null,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? AppColors.textMutedDark
                          : AppColors.textMutedLight,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
