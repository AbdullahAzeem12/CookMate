import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class RecipeMetadataRow extends StatelessWidget {
  final int totalMinutes;
  final int servings;
  final String difficulty;
  final bool isDarkText;

  const RecipeMetadataRow({
    super.key,
    required this.totalMinutes,
    required this.servings,
    required this.difficulty,
    this.isDarkText = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isDarkText
        ? theme.textTheme.bodySmall?.color ?? AppColors.textMutedLight
        : Colors.white.withValues(alpha: 0.9);

    final style = TextStyle(
      color: color,
      fontSize: 12,
      fontWeight: FontWeight.w500,
    );

    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.schedule_rounded,
            size: 13,
            color: isDarkText ? AppColors.forestGreen : AppColors.citrusLime,
          ),
          const SizedBox(width: 3),
          Text('$totalMinutes min', style: style),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text('•', style: style),
          ),
          Icon(
            Icons.people_alt_outlined,
            size: 13,
            color: isDarkText ? AppColors.forestGreen : AppColors.citrusLime,
          ),
          const SizedBox(width: 3),
          Text('$servings srv', style: style),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text('•', style: style),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: _getDifficultyColor(difficulty).withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              difficulty,
              style: style.copyWith(
                color: _getDifficultyColor(difficulty),
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getDifficultyColor(String diff) {
    switch (diff.toLowerCase()) {
      case 'easy':
        return const Color(0xFF2E7D32);
      case 'medium':
        return const Color(0xFFEF6C00);
      case 'hard':
        return const Color(0xFFC62828);
      default:
        return AppColors.citrusLime;
    }
  }
}
