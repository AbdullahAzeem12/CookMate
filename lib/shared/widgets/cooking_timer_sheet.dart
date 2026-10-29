import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../features/recipes/domain/models/recipe.dart';
import 'bounce_tap.dart';
import 'glass_card.dart';

enum TimerMode { step, total }

class CookingTimerSheet extends StatefulWidget {
  final Recipe recipe;
  final int? adjustedServings;
  final int? adjustedPrepMinutes;
  final int? adjustedCookMinutes;

  const CookingTimerSheet({
    super.key,
    required this.recipe,
    this.adjustedServings,
    this.adjustedPrepMinutes,
    this.adjustedCookMinutes,
  });

  static Future<void> show(
    BuildContext context,
    Recipe recipe, {
    int? adjustedServings,
    int? adjustedPrepMinutes,
    int? adjustedCookMinutes,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CookingTimerSheet(
        recipe: recipe,
        adjustedServings: adjustedServings,
        adjustedPrepMinutes: adjustedPrepMinutes,
        adjustedCookMinutes: adjustedCookMinutes,
      ),
    );
  }

  @override
  State<CookingTimerSheet> createState() => _CookingTimerSheetState();
}

class _CookingTimerSheetState extends State<CookingTimerSheet> {
  int _currentStepIndex = 0;
  TimerMode _timerMode = TimerMode.step;
  final Set<int> _completedStepIndices = {};

  // Step-Specific Timer State
  Timer? _stepTimer;
  int _stepRemainingSeconds = 300;
  int _stepTotalSeconds = 300;
  bool _isStepRunning = false;

  // Recipe-Wide Total Cook Timer State
  Timer? _totalCookTimer;
  int _totalCookRemainingSeconds = 1800;
  int _totalCookTotalSeconds = 1800;
  bool _isTotalRunning = false;

  @override
  void initState() {
    super.initState();
    // Initialize Total Cook Timer
    final totalSec = _activeCookMinutes > 0 ? _activeCookMinutes * 60 : 900;
    _totalCookTotalSeconds = totalSec;
    _totalCookRemainingSeconds = totalSec;

    // Initialize Step Timer for the opening step
    _loadStepTimerForStep(0);
  }

  @override
  void dispose() {
    _stepTimer?.cancel();
    _totalCookTimer?.cancel();
    super.dispose();
  }

  int get _activeCookMinutes =>
      widget.adjustedCookMinutes ?? widget.recipe.cookMinutes;
  int get _activePrepMinutes =>
      widget.adjustedPrepMinutes ?? widget.recipe.prepMinutes;
  int get _activeTotalMinutes => _activePrepMinutes + _activeCookMinutes;

  // Active Timer properties according to current view mode
  int get _remainingSeconds =>
      _timerMode == TimerMode.step ? _stepRemainingSeconds : _totalCookRemainingSeconds;
  int get _totalSeconds =>
      _timerMode == TimerMode.step ? _stepTotalSeconds : _totalCookTotalSeconds;
  bool get _isRunning =>
      _timerMode == TimerMode.step ? _isStepRunning : _isTotalRunning;

  void _loadStepTimerForStep(int stepIndex) {
    _stepTimer?.cancel();
    _isStepRunning = false;

    final instructions = widget.recipe.instructions;
    final currentStep = (instructions.isNotEmpty && stepIndex < instructions.length)
        ? instructions[stepIndex]
        : '';
    final defaultSec = instructions.isNotEmpty
        ? (_activeCookMinutes * 60) ~/ instructions.length
        : 300;
    final extracted = _extractDurationSeconds(
      currentStep,
      defaultSec > 30 ? defaultSec : 300,
    );
    _stepTotalSeconds = extracted;
    _stepRemainingSeconds = extracted;
  }

  int _extractDurationSeconds(String text, int fallbackSeconds) {
    if (text.isEmpty) return fallbackSeconds;

    // 1. Check for hour patterns (e.g. "3-4 hours", "1 hour")
    final hourMatch = RegExp(
      r'(\d+(?:\.\d+)?)\s*(?:-|to)?\s*(\d+(?:\.\d+)?)?\s*(?:hours|hour|hrs|hr)',
      caseSensitive: false,
    ).firstMatch(text);
    if (hourMatch != null) {
      final h1 = double.tryParse(hourMatch.group(1) ?? '') ?? 1.0;
      final h2 = double.tryParse(hourMatch.group(2) ?? '');
      final hours = h2 != null ? (h1 + h2) / 2 : h1;
      return (hours * 3600).round();
    }

    // 2. Check for minute patterns (e.g. "8 minutes", "9-11 minutes", "30-35 mins")
    final minMatch = RegExp(
      r'(\d+(?:\.\d+)?)\s*(?:-|to)?\s*(\d+(?:\.\d+)?)?\s*(?:minutes|minute|mins|min)',
      caseSensitive: false,
    ).firstMatch(text);
    if (minMatch != null) {
      final m1 = double.tryParse(minMatch.group(1) ?? '') ?? 5.0;
      final m2 = double.tryParse(minMatch.group(2) ?? '');
      final mins = m2 != null ? (m1 + m2) / 2 : m1;
      return (mins * 60).round();
    }

    // 3. Check for second patterns (e.g. "60 seconds", "30 secs")
    final secMatch = RegExp(
      r'(\d+)\s*(?:-|to)?\s*(\d+)?\s*(?:seconds|second|secs|sec)',
      caseSensitive: false,
    ).firstMatch(text);
    if (secMatch != null) {
      final s1 = int.tryParse(secMatch.group(1) ?? '') ?? 60;
      final s2 = int.tryParse(secMatch.group(2) ?? '');
      final secs = s2 != null ? ((s1 + s2) ~/ 2) : s1;
      return secs;
    }

    return fallbackSeconds;
  }

  void _adjustSeconds(int delta) {
    HapticFeedback.lightImpact();
    setState(() {
      if (_timerMode == TimerMode.step) {
        final newRemaining = _stepRemainingSeconds + delta;
        if (newRemaining > 0) {
          _stepRemainingSeconds = newRemaining;
          if (_stepRemainingSeconds > _stepTotalSeconds) {
            _stepTotalSeconds = _stepRemainingSeconds;
          }
        }
      } else {
        final newRemaining = _totalCookRemainingSeconds + delta;
        if (newRemaining > 0) {
          _totalCookRemainingSeconds = newRemaining;
          if (_totalCookRemainingSeconds > _totalCookTotalSeconds) {
            _totalCookTotalSeconds = _totalCookRemainingSeconds;
          }
        }
      }
    });
  }

  void _toggleTimer() {
    HapticFeedback.selectionClick();
    if (_timerMode == TimerMode.step) {
      if (_isStepRunning) {
        _stepTimer?.cancel();
        setState(() => _isStepRunning = false);
      } else {
        setState(() => _isStepRunning = true);
        _stepTimer = Timer.periodic(const Duration(seconds: 1), (t) {
          if (_stepRemainingSeconds > 0) {
            setState(() => _stepRemainingSeconds--);
          } else {
            t.cancel();
            setState(() => _isStepRunning = false);
            HapticFeedback.heavyImpact();
            _notifyTimerComplete('Step ${_currentStepIndex + 1} timer complete! ⏰');
          }
        });
      }
    } else {
      if (_isTotalRunning) {
        _totalCookTimer?.cancel();
        setState(() => _isTotalRunning = false);
      } else {
        setState(() => _isTotalRunning = true);
        _totalCookTimer = Timer.periodic(const Duration(seconds: 1), (t) {
          if (_totalCookRemainingSeconds > 0) {
            setState(() => _totalCookRemainingSeconds--);
          } else {
            t.cancel();
            setState(() => _isTotalRunning = false);
            HapticFeedback.heavyImpact();
            _notifyTimerComplete('Total cooking time complete! 🍲✨');
          }
        });
      }
    }
  }

  void _resetTimer() {
    HapticFeedback.lightImpact();
    setState(() {
      if (_timerMode == TimerMode.step) {
        _stepTimer?.cancel();
        _isStepRunning = false;
        _stepRemainingSeconds = _stepTotalSeconds;
      } else {
        _totalCookTimer?.cancel();
        _isTotalRunning = false;
        _totalCookRemainingSeconds = _totalCookTotalSeconds;
      }
    });
  }

  void _goToStep(int newIndex) {
    if (newIndex == _currentStepIndex) return;
    HapticFeedback.selectionClick();
    setState(() {
      _currentStepIndex = newIndex;
      _loadStepTimerForStep(newIndex);
    });
  }

  void _notifyTimerComplete(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.timer_off_rounded, color: AppColors.citrusLime),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.forestGreen,
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: '+1 min',
          textColor: AppColors.citrusLime,
          onPressed: () {
            _adjustSeconds(60);
            _toggleTimer();
          },
        ),
      ),
    );
  }

  String _formatTime(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;

    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final totalSteps = widget.recipe.instructions.length;
    final currentStep = totalSteps > 0
        ? widget.recipe.instructions[_currentStepIndex]
        : 'Prepare ingredients according to recipe directions.';
    final timerProgress = _totalSeconds > 0
        ? (_remainingSeconds / _totalSeconds).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      height: MediaQuery.of(context).size.height * 0.92,
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
          // Drag Handle
          const SizedBox(height: 12),
          Container(
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header with Zero-Overflow Ellipsis
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                  tooltip: 'Close cooking mode',
                ),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Step ${_currentStepIndex + 1} of $totalSteps',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.recipe.title,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.8),
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 48), // Symmetrical right balance
              ],
            ),
          ),

          // Real-World Cooking Timeline Synchronizer Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF142B23)
                    : const Color(0xFFEAF2EB),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.forestGreen.withValues(alpha: 0.15),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildSyncTimeChip(
                      context,
                      label: 'Prep Time',
                      value: '$_activePrepMinutes min',
                      icon: Icons.kitchen_rounded,
                      color: AppColors.citrusLime,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 24,
                    color: Colors.grey.withValues(alpha: 0.3),
                  ),
                  Expanded(
                    child: _buildSyncTimeChip(
                      context,
                      label: 'Cook Time',
                      value: '$_activeCookMinutes min',
                      icon: Icons.local_fire_department_rounded,
                      color: AppColors.softCoral,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 24,
                    color: Colors.grey.withValues(alpha: 0.3),
                  ),
                  Expanded(
                    child: _buildSyncTimeChip(
                      context,
                      label: 'Total Time',
                      value: '$_activeTotalMinutes min',
                      icon: Icons.schedule_rounded,
                      color: AppColors.forestGreen,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 10),

          // Interactive Segmented Step Progress Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: List.generate(totalSteps, (index) {
                final isCurrent = index == _currentStepIndex;
                final isCompleted = _completedStepIndices.contains(index) || index < _currentStepIndex;

                return Expanded(
                  child: GestureDetector(
                    onTap: () => _goToStep(index),
                    child: Container(
                      height: 6,
                      margin: EdgeInsets.symmetric(horizontal: totalSteps > 6 ? 1.5 : 2.5),
                      decoration: BoxDecoration(
                        color: isCurrent
                            ? AppColors.citrusLime
                            : (isCompleted
                                ? AppColors.forestGreen
                                : (isDark
                                    ? const Color(0xFF1B382D)
                                    : const Color(0xFFE2EADF))),
                        borderRadius: BorderRadius.circular(4),
                        boxShadow: isCurrent
                            ? [
                                BoxShadow(
                                  color: AppColors.citrusLime.withValues(alpha: 0.5),
                                  blurRadius: 6,
                                  spreadRadius: 1,
                                ),
                              ]
                            : null,
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),

          const SizedBox(height: 14),

          // Scrollable Instruction & Interactive Sync Timer
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Step Number & Custom Non-Overflowing Responsive Pill Switcher
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: _completedStepIndices.contains(_currentStepIndex)
                              ? AppColors.forestGreen
                              : (isDark ? AppColors.forestGreen : AppColors.deepEmerald),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: _completedStepIndices.contains(_currentStepIndex)
                            ? const Icon(Icons.check_rounded, color: Colors.white, size: 20)
                            : Text(
                                '${_currentStepIndex + 1}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                ),
                              ),
                      ),
                      const SizedBox(width: 10),
                      // Custom Responsive Pill Switcher
                      Expanded(
                        child: Container(
                          height: 38,
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF142B23)
                                : Colors.black.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.08)
                                  : Colors.black.withValues(alpha: 0.06),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: () {
                                    HapticFeedback.selectionClick();
                                    setState(() => _timerMode = TimerMode.step);
                                  },
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: _timerMode == TimerMode.step
                                          ? AppColors.forestGreen
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(11),
                                      boxShadow: _timerMode == TimerMode.step
                                          ? [
                                              BoxShadow(
                                                color: AppColors.forestGreen.withValues(alpha: 0.3),
                                                blurRadius: 4,
                                                offset: const Offset(0, 1),
                                              ),
                                            ]
                                          : null,
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          _isStepRunning
                                              ? Icons.hourglass_top_rounded
                                              : Icons.timer_outlined,
                                          size: 14,
                                          color: _timerMode == TimerMode.step
                                              ? Colors.white
                                              : (_isStepRunning
                                                  ? AppColors.softCoral
                                                  : (isDark
                                                      ? AppColors.textLight
                                                      : AppColors.textDark)),
                                        ),
                                        const SizedBox(width: 4),
                                        Flexible(
                                          child: Text(
                                            _isStepRunning
                                                ? 'Step (${_formatTime(_stepRemainingSeconds)})'
                                                : 'Step Timer',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color: _timerMode == TimerMode.step
                                                  ? Colors.white
                                                  : (isDark
                                                      ? AppColors.textLight
                                                      : AppColors.textDark),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: () {
                                    HapticFeedback.selectionClick();
                                    setState(() => _timerMode = TimerMode.total);
                                  },
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: _timerMode == TimerMode.total
                                          ? AppColors.forestGreen
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(11),
                                      boxShadow: _timerMode == TimerMode.total
                                          ? [
                                              BoxShadow(
                                                color: AppColors.forestGreen.withValues(alpha: 0.3),
                                                blurRadius: 4,
                                                offset: const Offset(0, 1),
                                              ),
                                            ]
                                          : null,
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          _isTotalRunning
                                              ? Icons.local_fire_department_rounded
                                              : Icons.hourglass_bottom_rounded,
                                          size: 14,
                                          color: _timerMode == TimerMode.total
                                              ? Colors.white
                                              : (_isTotalRunning
                                                  ? AppColors.softCoral
                                                  : (isDark
                                                      ? AppColors.textLight
                                                      : AppColors.textDark)),
                                        ),
                                        const SizedBox(width: 4),
                                        Flexible(
                                          child: Text(
                                            _isTotalRunning
                                                ? 'Total (${_formatTime(_totalCookRemainingSeconds)})'
                                                : 'Total Cook',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color: _timerMode == TimerMode.total
                                                  ? Colors.white
                                                  : (isDark
                                                      ? AppColors.textLight
                                                      : AppColors.textDark),
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
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Step Instruction Text
                  Text(
                    currentStep,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                      fontSize: 18.5,
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Chef's Guidance Card
                  GlassSurface(
                    borderRadius: 18,
                    blur: 10,
                    padding: const EdgeInsets.all(14),
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
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Chef's Guidance",
                                style: theme.textTheme.labelLarge?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.forestGreen,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                _timerMode == TimerMode.step
                                    ? "This timer is synchronized with the recommended duration for Step ${_currentStepIndex + 1}."
                                    : "Tracking the full ${widget.recipe.cookMinutes}-minute active cooking duration for ${widget.recipe.title}.",
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: isDark
                                      ? AppColors.textLight
                                      : AppColors.textDark,
                                  fontSize: 12.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Interactive Cooking Timer Card - Guaranteed 100% Zero Pixel Overflow
                  GlassSurface(
                    borderRadius: 22,
                    blur: 14,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    backgroundColor: isDark
                        ? const Color(0xFF162D25)
                        : Colors.white,
                    borderColor: isDark
                        ? (_isRunning
                            ? AppColors.softCoral.withValues(alpha: 0.35)
                            : Colors.white.withValues(alpha: 0.08))
                        : (_isRunning
                            ? AppColors.softCoral.withValues(alpha: 0.25)
                            : Colors.black.withValues(alpha: 0.06)),
                    child: Column(
                      children: [
                        // Row 1: Circular Progress Ring, High-Contrast Time Digits, Status Text, & Reset
                        Row(
                          children: [
                            // Animated Timer Progress Ring
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                SizedBox(
                                  width: 48,
                                  height: 48,
                                  child: CircularProgressIndicator(
                                    value: timerProgress,
                                    strokeWidth: 4,
                                    backgroundColor: isDark
                                        ? Colors.white.withValues(alpha: 0.1)
                                        : Colors.grey.withValues(alpha: 0.2),
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      _isRunning
                                          ? AppColors.softCoral
                                          : (isDark
                                              ? AppColors.citrusLime
                                              : AppColors.forestGreen),
                                    ),
                                  ),
                                ),
                                Icon(
                                  _isRunning
                                      ? Icons.hourglass_top_rounded
                                      : Icons.timer_outlined,
                                  size: 22,
                                  color: _isRunning
                                      ? AppColors.softCoral
                                      : (isDark
                                          ? AppColors.citrusLime
                                          : AppColors.forestGreen),
                                ),
                              ],
                            ),
                            const SizedBox(width: 14),

                            // Time Digits & Live Status
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _formatTime(_remainingSeconds),
                                    style: theme.textTheme.headlineMedium?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      fontFeatures: const [
                                        FontFeature.tabularFigures(),
                                      ],
                                      letterSpacing: 1.2,
                                      fontSize: 30,
                                      color: _isRunning
                                          ? (_remainingSeconds <= 10
                                              ? AppColors.softCoral
                                              : null)
                                          : null,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      Container(
                                        width: 7,
                                        height: 7,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: _isRunning
                                              ? AppColors.softCoral
                                              : (_remainingSeconds < _totalSeconds
                                                  ? AppColors.goldenAmber
                                                  : AppColors.citrusLime),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          _isRunning
                                              ? 'Synchronized Cooking In Progress'
                                              : (_remainingSeconds < _totalSeconds
                                                  ? 'Timer paused'
                                                  : 'Ready to start timing'),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: theme.textTheme.bodySmall?.copyWith(
                                            color: _isRunning
                                                ? AppColors.softCoral
                                                : theme.textTheme.bodySmall?.color,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            // Reset Button (visible when time has been modified)
                            if (_remainingSeconds < _totalSeconds)
                              IconButton(
                                icon: const Icon(Icons.refresh_rounded),
                                tooltip: 'Reset to original time',
                                color: isDark
                                    ? AppColors.citrusLime
                                    : AppColors.forestGreen,
                                onPressed: _resetTimer,
                              ),
                          ],
                        ),

                        const SizedBox(height: 14),

                        // Row 2: Full-Width Ergonomic Touch Target Start / Pause Action Button
                        BounceTap(
                          onTap: _toggleTimer,
                          child: Container(
                            width: double.infinity,
                            height: 48,
                            decoration: BoxDecoration(
                              gradient: _isRunning
                                  ? const LinearGradient(
                                      colors: [
                                        Color(0xFFE74C3C),
                                        Color(0xFFC0392B),
                                      ],
                                    )
                                  : AppColors.primaryGradient,
                              borderRadius: BorderRadius.circular(15),
                              boxShadow: [
                                BoxShadow(
                                  color: (_isRunning
                                          ? AppColors.softCoral
                                          : AppColors.forestGreen)
                                      .withValues(alpha: 0.35),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _isRunning
                                      ? Icons.pause_rounded
                                      : Icons.play_arrow_rounded,
                                  color: _isRunning
                                      ? Colors.white
                                      : AppColors.citrusLime,
                                  size: 22,
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    _isRunning ? 'Pause Timer' : 'Start Cooking Timer',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: _isRunning
                                          ? Colors.white
                                          : AppColors.citrusLime,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 15,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),
                        Divider(
                          height: 1,
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.1)
                              : Colors.black.withValues(alpha: 0.08),
                        ),
                        const SizedBox(height: 10),

                        // Row 3: Quick Time Adjustment Fine-Tuning Controls
                        Row(
                          children: [
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 2),
                                child: _buildAdjustChip(
                                  label: '-1 min',
                                  onTap: () => _adjustSeconds(-60),
                                  enabled: _remainingSeconds > 60,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 2),
                                child: _buildAdjustChip(
                                  label: '+30s',
                                  onTap: () => _adjustSeconds(30),
                                  enabled: true,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 2),
                                child: _buildAdjustChip(
                                  label: '+1 min',
                                  onTap: () => _adjustSeconds(60),
                                  enabled: true,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 2),
                                child: _buildAdjustChip(
                                  label: '+5 mins',
                                  onTap: () => _adjustSeconds(300),
                                  enabled: true,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Chef's Pro Note banner in timer sheet
                  if (widget.recipe.chefNotes != null &&
                      widget.recipe.chefNotes!.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF142B23)
                            : const Color(0xFFF1F8F4),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: (isDark
                                  ? AppColors.citrusLime
                                  : AppColors.forestGreen)
                              .withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.psychology_alt_rounded,
                            size: 18,
                            color: isDark
                                ? AppColors.citrusLime
                                : AppColors.forestGreen,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Chef's Intelligence:",
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                    color: isDark
                                        ? AppColors.citrusLime
                                        : AppColors.forestGreen,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  widget.recipe.chefNotes!,
                                  style: TextStyle(
                                    fontSize: 12,
                                    height: 1.4,
                                    color: isDark
                                        ? AppColors.textLight.withValues(
                                            alpha: 0.85,
                                          )
                                        : AppColors.textDark.withValues(
                                            alpha: 0.8,
                                          ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),

          // Bottom Action Stepper Controls
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
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
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  if (_currentStepIndex > 0) ...[
                    Expanded(
                      flex: 1,
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
                        onPressed: () => _goToStep(_currentStepIndex - 1),
                        icon: const Icon(Icons.arrow_back_rounded, size: 18),
                        label: const Text('Previous'),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    flex: _currentStepIndex > 0 ? 2 : 1,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _currentStepIndex < totalSteps - 1
                            ? AppColors.softCoral
                            : AppColors.forestGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        if (_currentStepIndex < totalSteps - 1) {
                          setState(() {
                            _completedStepIndices.add(_currentStepIndex);
                            _currentStepIndex++;
                            _loadStepTimerForStep(_currentStepIndex);
                          });
                        } else {
                          _completedStepIndices.add(_currentStepIndex);
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Row(
                                children: [
                                  Icon(Icons.stars_rounded, color: AppColors.citrusLime),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text('Bon Appétit! Recipe completed! 🍽️✨'),
                                  ),
                                ],
                              ),
                              backgroundColor: AppColors.forestGreen,
                              duration: Duration(seconds: 4),
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
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSyncTimeChip(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 9.5,
                    color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdjustChip({
    required String label,
    required VoidCallback onTap,
    required bool enabled,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 7),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: enabled
                ? (isDark
                    ? AppColors.citrusLime.withValues(alpha: 0.12)
                    : AppColors.forestGreen.withValues(alpha: 0.08))
                : Colors.grey.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: enabled
                  ? (isDark
                      ? AppColors.citrusLime.withValues(alpha: 0.25)
                      : AppColors.forestGreen.withValues(alpha: 0.20))
                  : Colors.transparent,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: enabled
                  ? (isDark ? AppColors.citrusLime : AppColors.forestGreen)
                  : Colors.grey,
            ),
          ),
        ),
      ),
    );
  }
}
