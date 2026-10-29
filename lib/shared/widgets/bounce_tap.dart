import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A high-performance interactive tactile wrapper that rapidly compresses
/// on press-down (~70ms) and snaps back with an elastic spring overshoot (~140ms)
/// upon tap release, delivering a satisfying, tactile physical feel.
///
/// When [awaitBounce] is true (default for recipe cards), the card completes its
/// rapid compression and spring bounce-back before [onTap] is called, ensuring the user
/// clearly and smoothly sees the card bounce before the new screen opens.
class BounceTap extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double shrinkScale;
  final Duration downDuration;
  final Duration upDuration;
  final bool enableHaptics;
  final bool awaitBounce;
  final HitTestBehavior behavior;

  const BounceTap({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.shrinkScale = 0.92,
    this.downDuration = const Duration(milliseconds: 70),
    this.upDuration = const Duration(milliseconds: 140),
    this.enableHaptics = true,
    this.awaitBounce = false,
    this.behavior = HitTestBehavior.opaque,
  });

  @override
  State<BounceTap> createState() => _BounceTapState();
}

class _BounceTapState extends State<BounceTap>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;
  bool _isHandlingTap = false;
  DateTime _tapDownTime = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.downDuration,
      value: 1.0, // Resting state is 1.0
    );
    _buildScaleAnimation();
  }

  void _buildScaleAnimation() {
    // Spring recoil sequence:
    // When controller goes from 0.0 -> 1.0, scale goes from shrinkScale -> 1.035 (overshoot) -> 1.000 (resting).
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: widget.shrinkScale, end: 1.035)
            .chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 60,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.035, end: 1.000)
            .chain(CurveTween(curve: Curves.easeInOutQuad)),
        weight: 40,
      ),
    ]).animate(_controller);
  }

  @override
  void didUpdateWidget(BounceTap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.shrinkScale != widget.shrinkScale) {
      _buildScaleAnimation();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.onTap == null && widget.onLongPress == null) return;
    if (_isHandlingTap) return;
    _isPressed = true;
    _tapDownTime = DateTime.now();
    if (widget.enableHaptics) {
      HapticFeedback.lightImpact();
    }
    // Rapid compression from resting (1.0) to compressed (0.0)
    _controller.animateTo(
      0.0,
      duration: widget.downDuration,
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _handleTapUp(TapUpDetails details) async {
    if (!_isPressed || _isHandlingTap) return;
    _isPressed = false;

    if (widget.awaitBounce) {
      _isHandlingTap = true;
      try {
        // Ensure minimum punch-down time has completed so the shrink is clearly visible
        final elapsed = DateTime.now().difference(_tapDownTime).inMilliseconds;
        final targetDownMs = widget.downDuration.inMilliseconds;
        if (elapsed < targetDownMs) {
          final remaining = (targetDownMs - elapsed).clamp(10, targetDownMs);
          await _controller.animateTo(
            0.0,
            duration: Duration(milliseconds: remaining),
            curve: Curves.easeOutCubic,
          );
        }

        // Fire the rapid spring bounce return (0.0 -> 1.0 through 1.035 overshoot)
        await _controller.animateTo(
          1.0,
          duration: widget.upDuration,
          curve: Curves.easeOutCubic,
        );

        // Now that the card has visibly and smoothly bounced back, execute navigation
        if (mounted) {
          widget.onTap?.call();
        }
      } finally {
        if (mounted) {
          _isHandlingTap = false;
        }
      }
    } else {
      // Immediate action triggering
      _controller.animateTo(
        1.0,
        duration: widget.upDuration,
        curve: Curves.easeOutCubic,
      );
      widget.onTap?.call();
    }
  }

  void _handleTapCancel() {
    if (!_isPressed || _isHandlingTap) return;
    _isPressed = false;
    // Graceful reset without triggering tap
    _controller.animateTo(
      1.0,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: widget.onTap != null
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      child: GestureDetector(
        behavior: widget.behavior,
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        onLongPress: widget.onLongPress != null
            ? () {
                if (widget.enableHaptics) {
                  HapticFeedback.mediumImpact();
                }
                widget.onLongPress?.call();
              }
            : null,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: child,
            );
          },
          child: widget.child,
        ),
      ),
    );
  }
}
