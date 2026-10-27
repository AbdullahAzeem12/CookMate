import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../features/recipes/domain/models/recipe.dart';
import 'glass_card.dart';

class CookingTimerSheet extends StatefulWidget {
  final Recipe recipe;

  const CookingTimerSheet({super.key, required this.recipe});

  static Future<void> show(BuildContext context, Recipe recipe) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CookingTimerSheet(recipe: recipe),
    );
  }

  @override
  State<CookingTimerSheet> createState() => _CookingTimerSheetState();
}

class _CookingTimerSheetState extends State<CookingTimerSheet> {
  int _currentStepIndex = 0;
  Timer? _timer;
  int _remainingSeconds = 300; // default 5 mins
  final int _totalSeconds = 300;
  bool _isRunning = false;

  @override
  void initState() {
    super.initState();
    // Approximate step timer from recipe cook time
    final stepSeconds =
        (widget.recipe.cookMinutes * 60) ~/
        (widget.recipe.instructions.isNotEmpty
            ? widget.recipe.instructions.length
            : 1);
    _remainingSeconds = stepSeconds > 30 ? stepSeconds : 300;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _toggleTimer() {
    if (_isRunning) {
      _timer?.cancel();
      setState(() => _isRunning = false);
    } else {
      setState(() => _isRunning = true);
      _timer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (_remainingSeconds > 0) {
          setState(() => _remainingSeconds--);
        } else {
          t.cancel();
          setState(() => _isRunning = false);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Step ${_currentStepIndex + 1} timer finished! ⏰',
                ),
                backgroundColor: AppColors.forestGreen,
              ),
            );
          }
        }
      });
    }
  }

  void _resetTimer() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _remainingSeconds = _totalSeconds;
    });
  }

  String _formatTime(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final totalSteps = widget.recipe.instructions.length;
    final currentStep = widget.recipe.instructions[_currentStepIndex];
    final progress = (_currentStepIndex + 1) / totalSteps;

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: BoxDecoration(
        color: isDark ? AppColors.deepSurface : AppColors.warmCream,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.12)
              : Colors.black.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        children: [
          // Drag handle & Header
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
                Text(
                  'Step ${_currentStepIndex + 1} of $totalSteps',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 48), // balance close icon
              ],
            ),
          ),
          // Step progress bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: isDark
                    ? const Color(0xFF1B382D)
                    : const Color(0xFFE2EADF),
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppColors.citrusLime,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Scrollable instruction & timer
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Step number badge
                  Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      color: AppColors.forestGreen,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${_currentStepIndex + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Step Instruction text
                  Text(
                    currentStep,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Chef's pro tip card
                  GlassSurface(
                    borderRadius: 18,
                    blur: 10,
                    padding: const EdgeInsets.all(16),
                    backgroundColor: isDark
                        ? const Color(0xFF1B382D).withValues(alpha: 0.5)
                        : const Color(0xFFE8F2EC),
                    borderColor: AppColors.forestGreen.withValues(alpha: 0.15),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.lightbulb_outline_rounded,
                          color: AppColors.forestGreen,
                          size: 22,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Chef's Tip",
                                style: theme.textTheme.labelLarge?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.forestGreen,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Keep your heat gentle and steady so ingredients caramelize evenly without burning.",
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: isDark
                                      ? AppColors.textLight
                                      : AppColors.textDark,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Interactive Cooking Timer Card
                  GlassSurface(
                    borderRadius: 22,
                    blur: 14,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    backgroundColor: isDark
                        ? const Color(0xFF162D25)
                        : Colors.white,
                    borderColor: Colors.black.withValues(alpha: 0.06),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.timer_outlined,
                              size: 28,
                              color: isDark
                                  ? AppColors.citrusLime
                                  : AppColors.forestGreen,
                            ),
                            const SizedBox(width: 14),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _formatTime(_remainingSeconds),
                                  style: theme.textTheme.headlineMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.w800,
                                        fontFeatures: const [
                                          FontFeature.tabularFigures(),
                                        ],
                                        letterSpacing: 1,
                                      ),
                                ),
                                Text(
                                  _isRunning
                                      ? 'Timer Running'
                                      : 'Ready to start',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: _isRunning
                                        ? AppColors.softCoral
                                        : theme.textTheme.bodySmall?.color,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            if (_remainingSeconds < _totalSeconds)
                              IconButton(
                                icon: const Icon(Icons.refresh_rounded),
                                tooltip: 'Reset timer',
                                onPressed: _resetTimer,
                              ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _isRunning
                                    ? AppColors.softCoral
                                    : AppColors.forestGreen,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 10,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              onPressed: _toggleTimer,
                              child: Text(_isRunning ? 'Pause' : 'Start'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),

          // Bottom Action Stepper Controls
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF132821) : Colors.white,
              border: Border(
                top: BorderSide(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.06),
                ),
              ),
            ),
            child: Row(
              children: [
                if (_currentStepIndex > 0)
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(
                          color: isDark
                              ? AppColors.citrusLime
                              : AppColors.forestGreen,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () {
                        setState(() {
                          _currentStepIndex--;
                          _resetTimer();
                        });
                      },
                      icon: const Icon(Icons.arrow_back_rounded, size: 18),
                      label: const Text('Previous'),
                    ),
                  )
                else
                  const Spacer(),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.softCoral,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () {
                      if (_currentStepIndex < totalSteps - 1) {
                        setState(() {
                          _currentStepIndex++;
                          _resetTimer();
                        });
                      } else {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Bon Appétit! Recipe completed! 🍽️✨',
                            ),
                            backgroundColor: AppColors.forestGreen,
                          ),
                        );
                      }
                    },
                    icon: Icon(
                      _currentStepIndex < totalSteps - 1
                          ? Icons.arrow_forward_rounded
                          : Icons.check_circle_rounded,
                      size: 18,
                    ),
                    label: Text(
                      _currentStepIndex < totalSteps - 1
                          ? 'Next Step'
                          : 'Finish Cooking',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
