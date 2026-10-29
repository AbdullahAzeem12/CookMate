import 'dart:ui';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// A premium liquid-glass card with an animated specular shimmer / glow border
/// tailored to CookMate's warm culinary green & gold palette.
class ShinyGlassCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final double borderRadius;
  final double blur;
  final bool enableShimmer;

  const ShinyGlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(24.0),
    this.margin = const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
    this.borderRadius = 28.0,
    this.blur = 18.0,
    this.enableShimmer = true,
  });

  @override
  State<ShinyGlassCard> createState() => _ShinyGlassCardState();
}

class _ShinyGlassCardState extends State<ShinyGlassCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    if (widget.enableShimmer) {
      _shimmerController.repeat();
    }
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final baseBg = isDark
        ? const Color(0xFF132B22).withValues(alpha: 0.72)
        : Colors.white.withValues(alpha: 0.78);

    final borderGradientColors = isDark
        ? [
            Colors.white.withValues(alpha: 0.35),
            AppColors.citrusLime.withValues(alpha: 0.65),
            AppColors.forestGreen.withValues(alpha: 0.20),
            Colors.white.withValues(alpha: 0.08),
            AppColors.citrusLime.withValues(alpha: 0.40),
          ]
        : [
            Colors.white.withValues(alpha: 0.95),
            AppColors.forestGreen.withValues(alpha: 0.25),
            AppColors.citrusLime.withValues(alpha: 0.50),
            Colors.white.withValues(alpha: 0.60),
            Colors.white.withValues(alpha: 0.95),
          ];

    final shadowColor = isDark
        ? Colors.black.withValues(alpha: 0.45)
        : AppColors.forestGreen.withValues(alpha: 0.12);

    return Container(
      margin: widget.margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 28,
            offset: const Offset(0, 10),
            spreadRadius: 2,
          ),
          if (isDark)
            BoxShadow(
              color: AppColors.citrusLime.withValues(alpha: 0.08),
              blurRadius: 36,
              spreadRadius: 0,
            ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: widget.blur,
            sigmaY: widget.blur,
          ),
          child: AnimatedBuilder(
            animation: _shimmerController,
            builder: (context, _) {
              final sweep = _shimmerController.value;

              return Container(
                decoration: BoxDecoration(
                  color: baseBg,
                  borderRadius: BorderRadius.circular(widget.borderRadius),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.12)
                        : Colors.white.withValues(alpha: 0.65),
                    width: 1.2,
                  ),
                ),
                child: CustomPaint(
                  painter: _ShinyBorderPainter(
                    borderRadius: widget.borderRadius,
                    shimmerProgress: sweep,
                    gradientColors: borderGradientColors,
                  ),
                  child: Stack(
                    children: [
                      // Subtle specular reflection arc at the very top of the glass
                      Positioned(
                        top: 0,
                        left: 24,
                        right: 24,
                        height: 1.5,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.white.withValues(alpha: 0.0),
                                Colors.white.withValues(alpha: isDark ? 0.6 : 0.9),
                                Colors.white.withValues(alpha: 0.0),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Card Content
                      Padding(
                        padding: widget.padding,
                        child: widget.child,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ShinyBorderPainter extends CustomPainter {
  final double borderRadius;
  final double shimmerProgress;
  final List<Color> gradientColors;

  _ShinyBorderPainter({
    required this.borderRadius,
    required this.shimmerProgress,
    required this.gradientColors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(
      rect.deflate(0.6),
      Radius.circular(borderRadius),
    );

    final angle = shimmerProgress * 2 * 3.1415926535;
    final sweepGradient = SweepGradient(
      center: Alignment.center,
      startAngle: 0.0,
      endAngle: 3.1415926535 * 2,
      colors: gradientColors,
      transform: GradientRotation(angle),
    );

    final paint = Paint()
      ..shader = sweepGradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;

    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(covariant _ShinyBorderPainter oldDelegate) {
    return oldDelegate.shimmerProgress != shimmerProgress;
  }
}

