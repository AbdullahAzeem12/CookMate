import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/glass_card.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _progressController;
  late final AnimationController _floatAndShineController;

  // Staggered entrance animations
  late final Animation<double> _logoScale;
  late final Animation<double> _logoOpacity;
  late final Animation<double> _textOpacity;
  late final Animation<Offset> _textSlide;
  late final Animation<double> _progressOpacity;

  bool _navigated = false;

  final List<String> _loadingTips = [
    '🔥 Firing up the culinary hearth...',
    '🥬 Handpicking crisp organic harvest...',
    '🧑‍🍳 Channeling Michelin-level craft...',
    '✨ Balancing delicate herb harmonies...',
    '🍽️ Welcome to your master kitchen!',
  ];

  @override
  void initState() {
    super.initState();

    // 7-second master countdown and progress controller
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 7),
    );

    // Continuous floating and specular shine sweep animation
    _floatAndShineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat();

    // Entrance curves
    _logoScale = Tween<double>(begin: 0.75, end: 1.0).animate(
      CurvedAnimation(
        parent: _progressController,
        curve: const Interval(0.0, 0.18, curve: Curves.easeOutBack),
      ),
    );

    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _progressController,
        curve: const Interval(0.0, 0.12, curve: Curves.easeIn),
      ),
    );

    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _progressController,
        curve: const Interval(0.10, 0.25, curve: Curves.easeIn),
      ),
    );

    _textSlide = Tween<Offset>(
      begin: const Offset(0.0, 0.25),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _progressController,
        curve: const Interval(0.10, 0.25, curve: Curves.easeOutCubic),
      ),
    );

    _progressOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _progressController,
        curve: const Interval(0.18, 0.32, curve: Curves.easeIn),
      ),
    );

    _progressController.forward().whenComplete(() {
      _navigateToHome();
    });
  }

  @override
  void dispose() {
    _progressController.dispose();
    _floatAndShineController.dispose();
    super.dispose();
  }

  void _navigateToHome() {
    if (_navigated || !mounted) return;
    _navigated = true;
    context.go('/');
  }

  String _getCurrentTip(double progress) {
    final index = (progress * _loadingTips.length).floor().clamp(
      0,
      _loadingTips.length - 1,
    );
    return _loadingTips[index];
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isCompact = size.width < AppConstants.compactBreakpoint;

    return Scaffold(
      backgroundColor: const Color(0xFF091712),
      body: Stack(
        children: [
          // 1. Deep Ambient Radial Glow Background
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0.0, -0.2),
                  radius: 1.2,
                  colors: [
                    Color(0xFF1B4332), // Deep Forest Center Glow
                    Color(0xFF0E271F), // Mid Emerald
                    Color(0xFF07130F), // Midnight Green Base
                  ],
                  stops: [0.0, 0.55, 1.0],
                ),
              ),
            ),
          ),

          // 2. Animated Ambient Mesh Glow Orbs
          AnimatedBuilder(
            animation: _floatAndShineController,
            builder: (context, _) {
              final t = _floatAndShineController.value * 2 * math.pi;
              return Stack(
                children: [
                  Positioned(
                    top: size.height * 0.18 + math.sin(t) * 20,
                    left: size.width * 0.5 - 140 + math.cos(t) * 25,
                    child: Container(
                      width: 280,
                      height: 280,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.citrusLime.withValues(alpha: 0.09),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.citrusLime.withValues(alpha: 0.18),
                            blurRadius: 90,
                            spreadRadius: 30,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: size.height * 0.40 - math.sin(t) * 15,
                    right: 20 + math.cos(t * 0.8) * 20,
                    child: Container(
                      width: 180,
                      height: 180,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF2D6A4F).withValues(alpha: 0.25),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0xFF2D6A4F),
                            blurRadius: 100,
                            spreadRadius: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),

          // 3. Top Action Bar with Skip Button
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 12, right: 16),
                child: GlassSurface(
                  borderRadius: 20,
                  blur: 16,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  backgroundColor: Colors.white.withValues(alpha: 0.10),
                  borderColor: Colors.white.withValues(alpha: 0.22),
                  onTap: _navigateToHome,
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Skip',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: AppColors.citrusLime,
                        size: 13,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 4. Central Content: 3D Logo, Floating Objects, Headings, Progress
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),

                    // Central 3D Logo Display with Floating Objects
                    SizedBox(
                      width: isCompact ? 300 : 360,
                      height: isCompact ? 300 : 360,
                      child: Stack(
                        alignment: Alignment.center,
                        clipBehavior: Clip.none,
                        children: [
                          // Rotating Radiant Aura Ring behind logo
                          AnimatedBuilder(
                            animation: _floatAndShineController,
                            builder: (context, _) {
                              final rotation =
                                  _floatAndShineController.value * 2 * math.pi;
                              return Transform.rotate(
                                angle: rotation,
                                child: Container(
                                  width: isCompact ? 240 : 270,
                                  height: isCompact ? 240 : 270,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: SweepGradient(
                                      colors: [
                                        AppColors.citrusLime.withValues(
                                          alpha: 0.0,
                                        ),
                                        AppColors.citrusLime.withValues(
                                          alpha: 0.35,
                                        ),
                                        AppColors.forestGreen.withValues(
                                          alpha: 0.5,
                                        ),
                                        AppColors.citrusLime.withValues(
                                          alpha: 0.0,
                                        ),
                                      ],
                                      stops: const [0.0, 0.5, 0.8, 1.0],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),

                          // Floating Culinary Objects / Emojis Orbiting the Logo
                          _buildFloatingItem(
                            emoji: '🌿',
                            baseOffset: const Offset(-115, -100),
                            phase: 0.0,
                            size: 44,
                          ),
                          _buildFloatingItem(
                            emoji: '🍅',
                            baseOffset: const Offset(118, -85),
                            phase: 1.2,
                            size: 46,
                          ),
                          _buildFloatingItem(
                            emoji: '✨',
                            baseOffset: const Offset(-125, 60),
                            phase: 2.5,
                            size: 40,
                          ),
                          _buildFloatingItem(
                            emoji: '🥑',
                            baseOffset: const Offset(120, 70),
                            phase: 3.8,
                            size: 48,
                          ),
                          _buildFloatingItem(
                            emoji: '🍋',
                            baseOffset: const Offset(0, -135),
                            phase: 4.6,
                            size: 42,
                          ),

                          // 3D Metallic Master Logo with Specular Shine Sweep
                          AnimatedBuilder(
                            animation: _progressController,
                            builder: (context, child) {
                              return Opacity(
                                opacity: _logoOpacity.value,
                                child: Transform.scale(
                                  scale: _logoScale.value,
                                  child: child,
                                ),
                              );
                            },
                            child: AnimatedBuilder(
                              animation: _floatAndShineController,
                              builder: (context, _) {
                                final t =
                                    _floatAndShineController.value *
                                    2 *
                                    math.pi;
                                final floatY = math.sin(t) * 8.0;
                                final floatScale =
                                    1.0 + math.sin(t * 1.5) * 0.018;

                                return Transform.translate(
                                  offset: Offset(0, floatY),
                                  child: Transform.scale(
                                    scale: floatScale,
                                    child: _buildShiny3DLogo(isCompact),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Headings with 3D Depth & Glowing Shadows
                    AnimatedBuilder(
                      animation: _progressController,
                      builder: (context, child) {
                        return Opacity(
                          opacity: _textOpacity.value,
                          child: SlideTransition(
                            position: _textSlide,
                            child: child,
                          ),
                        );
                      },
                      child: Column(
                        children: [
                          // App Title with Gradient Text & Radiant Glow
                          ShaderMask(
                            shaderCallback: (bounds) {
                              return const LinearGradient(
                                colors: [
                                  Color(0xFFEAF5EF),
                                  AppColors.citrusLime,
                                  Color(0xFFFFFFFF),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ).createShader(bounds);
                            },
                            child: const Text(
                              AppConstants.appName,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 44,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -1.0,
                                color: Colors.white,
                                shadows: [
                                  Shadow(
                                    color: Color(0x99C8E64A),
                                    blurRadius: 28,
                                    offset: Offset(0, 4),
                                  ),
                                  Shadow(
                                    color: Color(0xCC0F241D),
                                    blurRadius: 16,
                                    offset: Offset(0, 8),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 10),

                          // Tagline Pill Badge with Glass Surface
                          GlassSurface(
                            borderRadius: 20,
                            blur: 14,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 6,
                            ),
                            backgroundColor: Colors.white.withValues(
                              alpha: 0.08,
                            ),
                            borderColor: AppColors.citrusLime.withValues(
                              alpha: 0.35,
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.auto_awesome,
                                  color: AppColors.citrusLime,
                                  size: 15,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'YOUR PERSONAL KITCHEN COMPANION',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 44),

                    // Progress Bar Section (7-Second Continuous Loading)
                    AnimatedBuilder(
                      animation: _progressController,
                      builder: (context, _) {
                        final progress = _progressController.value;
                        final tip = _getCurrentTip(progress);
                        final percent = (progress * 100).toInt();

                        return Opacity(
                          opacity: _progressOpacity.value,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 360),
                            child: Column(
                              children: [
                                // Progress Info Row (Status text & percentage)
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: AnimatedSwitcher(
                                          duration: const Duration(
                                            milliseconds: 350,
                                          ),
                                          child: Text(
                                            tip,
                                            key: ValueKey(tip),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: Colors.white.withValues(
                                                alpha: 0.88,
                                              ),
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '$percent%',
                                        style: const TextStyle(
                                          color: AppColors.citrusLime,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 12),

                                // Glowing Liquid Gradient Progress Bar
                                Container(
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.4),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: Colors.white.withValues(
                                        alpha: 0.15,
                                      ),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.4,
                                        ),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: LayoutBuilder(
                                    builder: (context, barConstraints) {
                                      final fillWidth =
                                          barConstraints.maxWidth * progress;
                                      return Align(
                                        alignment: Alignment.centerLeft,
                                        child: Container(
                                          width: fillWidth,
                                          height: 10,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                            gradient: const LinearGradient(
                                              colors: [
                                                AppColors.forestGreen,
                                                Color(0xFF52B788),
                                                AppColors.citrusLime,
                                                Colors.white,
                                              ],
                                              stops: [0.0, 0.45, 0.88, 1.0],
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: AppColors.citrusLime
                                                    .withValues(alpha: 0.75),
                                                blurRadius: 14,
                                                spreadRadius: 1,
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Floating culinary element with sine-wave motion and frosted bubble
  Widget _buildFloatingItem({
    required String emoji,
    required Offset baseOffset,
    required double phase,
    required double size,
  }) {
    return AnimatedBuilder(
      animation: _floatAndShineController,
      builder: (context, _) {
        final t = _floatAndShineController.value * 2 * math.pi + phase;
        final dx = baseOffset.dx + math.cos(t) * 14.0;
        final dy = baseOffset.dy + math.sin(t * 1.2) * 16.0;
        final angle = math.sin(t * 0.8) * 0.18;

        return Transform.translate(
          offset: Offset(dx, dy),
          child: Transform.rotate(
            angle: angle,
            child: GlassSurface(
              borderRadius: size,
              blur: 12,
              padding: EdgeInsets.all(size * 0.16),
              backgroundColor: Colors.white.withValues(alpha: 0.14),
              borderColor: Colors.white.withValues(alpha: 0.35),
              shadows: [
                BoxShadow(
                  color: AppColors.deepEmerald.withValues(alpha: 0.45),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
                BoxShadow(
                  color: AppColors.citrusLime.withValues(alpha: 0.20),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ],
              child: SizedBox(
                width: size,
                height: size,
                child: Center(
                  child: Text(
                    emoji,
                    style: TextStyle(
                      fontSize: size * 0.58,
                      shadows: [
                        Shadow(
                          color: Colors.black.withValues(alpha: 0.5),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // 3D Logo Container with Specular Shine Effect
  Widget _buildShiny3DLogo(bool isCompact) {
    final logoSize = isCompact ? 190.0 : 220.0;

    return Container(
      width: logoSize,
      height: logoSize,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(42),
        boxShadow: [
          // Ambient Outer Emerald Glow
          BoxShadow(
            color: const Color(0xFF1B4332).withValues(alpha: 0.65),
            blurRadius: 40,
            spreadRadius: 10,
            offset: const Offset(0, 14),
          ),
          // Citrus Lime Specular Glow
          BoxShadow(
            color: AppColors.citrusLime.withValues(alpha: 0.35),
            blurRadius: 26,
            spreadRadius: 2,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(42),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // The generated 3D CookMate Logo Asset
            Image.asset(
              'assets/images/app_logo.png',
              width: logoSize,
              height: logoSize,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return _buildLogoFallback(logoSize);
              },
            ),

            // Animated Specular Diagonal Shine Sweep
            AnimatedBuilder(
              animation: _floatAndShineController,
              builder: (context, _) {
                final shinePos =
                    (_floatAndShineController.value * 2.5) - 0.75; // -0.75 to 1.75
                return ShaderMask(
                  blendMode: BlendMode.screen,
                  shaderCallback: (bounds) {
                    return LinearGradient(
                      begin: Alignment(-1.5 + shinePos * 2.0, -1.0),
                      end: Alignment(0.5 + shinePos * 2.0, 1.0),
                      colors: [
                        Colors.transparent,
                        Colors.white.withValues(alpha: 0.05),
                        Colors.white.withValues(alpha: 0.60),
                        Colors.white.withValues(alpha: 0.05),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.4, 0.5, 0.6, 1.0],
                    ).createShader(bounds);
                  },
                  child: Container(
                    width: logoSize,
                    height: logoSize,
                    color: Colors.white,
                  ),
                );
              },
            ),

            // Glass Border Ring
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(42),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.35),
                  width: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoFallback(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const RadialGradient(
          center: Alignment(0.0, -0.2),
          radius: 0.9,
          colors: [
            Color(0xFF1B4332),
            Color(0xFF0F241D),
            Color(0xFF07130F),
          ],
        ),
        borderRadius: BorderRadius.circular(42),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFFFD166),
                    Color(0xFFE9C46A),
                    Color(0xFF2D6A4F),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.citrusLime.withValues(alpha: 0.4),
                    blurRadius: 18,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Icon(
                Icons.restaurant_menu_rounded,
                size: size * 0.32,
                color: const Color(0xFF091712),
              ),
            ),
            const SizedBox(height: 10),
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [Color(0xFFFFFFFF), AppColors.citrusLime],
              ).createShader(bounds),
              child: const Text(
                'CookMate',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
