import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/services/password_validator.dart';

class PasswordStrengthBar extends StatelessWidget {
  final PasswordStrengthResult strength;

  const PasswordStrengthBar({
    super.key,
    required this.strength,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (strength.tier == PasswordStrengthTier.none) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        // 4-Bar visual indicator row
        Row(
          children: [
            for (int i = 1; i <= 4; i++)
              Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  height: 4.5,
                  margin: EdgeInsets.only(right: i < 4 ? 6.0 : 0.0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(3),
                    color: i <= strength.score
                        ? strength.color
                        : (isDark
                            ? Colors.white.withValues(alpha: 0.10)
                            : Colors.black.withValues(alpha: 0.08)),
                    boxShadow: i <= strength.score
                        ? [
                            BoxShadow(
                              color: strength.color.withValues(alpha: 0.45),
                              blurRadius: 4,
                            ),
                          ]
                        : null,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),

        // Strength Label and Quality Badge
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Password Security:',
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 12,
                color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: strength.color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: strength.color.withValues(alpha: 0.35),
                  width: 1,
                ),
              ),
              child: Text(
                strength.label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: strength.color,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Compact rules checklist
        Wrap(
          spacing: 12,
          runSpacing: 4,
          children: [
            _buildCheckItem(
              label: '8+ chars',
              isMet: strength.hasMinLength,
              isDark: isDark,
            ),
            _buildCheckItem(
              label: 'Upper & Lower',
              isMet: strength.hasUpper && strength.hasLower,
              isDark: isDark,
            ),
            _buildCheckItem(
              label: 'Number (0-9)',
              isMet: strength.hasDigit,
              isDark: isDark,
            ),
            _buildCheckItem(
              label: 'Symbol (!@#)',
              isMet: strength.hasSpecial,
              isDark: isDark,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCheckItem({
    required String label,
    required bool isMet,
    required bool isDark,
  }) {
    const activeColor = Color(0xFF2ECC71);
    final inactiveColor = isDark
        ? AppColors.textMutedDark.withValues(alpha: 0.6)
        : AppColors.textMutedLight.withValues(alpha: 0.7);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Icon(
            isMet ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
            key: ValueKey(isMet),
            size: 13,
            color: isMet ? activeColor : inactiveColor,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isMet ? FontWeight.w600 : FontWeight.w400,
            color: isMet ? (isDark ? Colors.white : AppColors.textDark) : inactiveColor,
          ),
        ),
      ],
    );
  }
}
