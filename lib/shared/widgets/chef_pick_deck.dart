import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../features/favorites/presentation/providers/favorites_providers.dart';
import '../../features/recipes/domain/models/recipe.dart';
import '../../features/recipes/presentation/providers/recipe_providers.dart';
import 'app_cached_network_image.dart';
import 'favorite_button.dart';
import 'glass_card.dart';
import 'recipe_metadata_row.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Constants for Swipe Physics and Stack Geometry
// ─────────────────────────────────────────────────────────────────────────────
const double _kDefaultCardHeight = 330.0;
const double _kStackExtraHeight = 25.0;
const double _kSwipeThreshold = 35.0; // Highly sensitive distance before committing swipe
const double _kFlingVelocityThreshold = 180.0; // Gentle flick threshold for effortless swiping
const int _kMaxVisibleDepth = 3;

// Resting stack offsets & rotations for that Daraz / Tinder diagonal depth
const Offset _kBackCard1Offset = Offset(8.0, 10.0);
const double _kBackCard1Rotation = -0.035; // ~ -2.0 degrees
const double _kBackCard1Scale = 0.94;
const double _kBackCard1Opacity = 0.85;

const Offset _kBackCard2Offset = Offset(-6.0, 18.0);
const double _kBackCard2Rotation = 0.025; // ~ +1.4 degrees
const double _kBackCard2Scale = 0.88;
const double _kBackCard2Opacity = 0.65;

// ─────────────────────────────────────────────────────────────────────────────
// Public Entry-Point Widget
// ─────────────────────────────────────────────────────────────────────────────

/// High-performance, diagonal swipable card deck for Chef's Choice / Featured Recipes.
///
/// Designed to sit directly in the Hero position on the Home screen.
/// - Full-width responsive layout matching the featured card.
/// - Diagonal + multi-directional swipe gestures with realistic physics.
/// - Acts directionally:
///     • Right  -> Save to Favorites (triggers state + feedback)
///     • Left   -> Skip to next recipe
///     • Up     -> Cook Now (opens recipe detail directly)
///     • Down   -> Save for later
/// - Stack depth effect (back cards fanned out and smoothly step forward on drag).
/// - Infinite loop (cards cycle seamlessly).
class ChefPickDeck extends ConsumerWidget {
  final double cardHeight;

  const ChefPickDeck({
    super.key,
    this.cardHeight = _kDefaultCardHeight,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chefsPick = ref.watch(chefsPickRecipesProvider);
    final allRecipesAsync = ref.watch(allRecipesProvider);

    final recipes = chefsPick.isNotEmpty
        ? chefsPick
        : (allRecipesAsync.value ?? <Recipe>[]);

    if (recipes.isEmpty) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = constraints.maxWidth;
        return _ChefPickDeckCore(
          recipes: recipes,
          cardWidth: cardWidth,
          cardHeight: cardHeight,
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Stateful Core Implementation
// ─────────────────────────────────────────────────────────────────────────────

class _ChefPickDeckCore extends ConsumerStatefulWidget {
  final List<Recipe> recipes;
  final double cardWidth;
  final double cardHeight;

  const _ChefPickDeckCore({
    required this.recipes,
    required this.cardWidth,
    required this.cardHeight,
  });

  @override
  ConsumerState<_ChefPickDeckCore> createState() => _ChefPickDeckCoreState();
}

enum _SwipeDirection { left, right, up, down }

class _ChefPickDeckCoreState extends ConsumerState<_ChefPickDeckCore>
    with TickerProviderStateMixin {
  late List<Recipe> _deck;

  // Drag tracking
  Offset _dragOffset = Offset.zero;
  Offset _dragVelocity = Offset.zero;
  double _totalDragDistance = 0.0;

  // Fly-out animation controller
  late AnimationController _flyController;
  late Animation<Offset> _flyAnimation;
  _SwipeDirection? _committedDirection;
  Recipe? _committedRecipe;

  // Spring-back animation controller
  late AnimationController _springController;
  Animation<Offset>? _springAnimation;

  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();
    _deck = List<Recipe>.from(widget.recipes);

    _flyController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
    )..addStatusListener(_onFlyAnimationStatus);

    _springController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
  }

  @override
  void didUpdateWidget(covariant _ChefPickDeckCore oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.recipes.length != widget.recipes.length) {
      final currentTopId = _deck.isNotEmpty ? _deck.first.id : null;
      _deck = List<Recipe>.from(widget.recipes);
      if (currentTopId != null) {
        final idx = _deck.indexWhere((r) => r.id == currentTopId);
        if (idx > 0) {
          final top = _deck.removeAt(idx);
          _deck.insert(0, top);
        }
      }
    }
  }

  @override
  void dispose() {
    _flyController.dispose();
    _springController.dispose();
    super.dispose();
  }

  // ── Gestures ───────────────────────────────────────────────────────────────

  void _onPanStart(DragStartDetails details) {
    if (_isAnimating) return;
    _springController.stop();
    _flyController.stop();
    setState(() {
      _dragOffset = Offset.zero;
      _totalDragDistance = 0.0;
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_isAnimating) return;
    setState(() {
      _dragOffset += details.delta;
      _totalDragDistance += details.delta.distance;
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (_isAnimating) return;

    _dragVelocity = details.velocity.pixelsPerSecond;
    final speed = _dragVelocity.distance;
    final distance = _dragOffset.distance;

    // Detect if this was a simple tap (finger down and lifted without dragging)
    if (_totalDragDistance < 8.0 && distance < 8.0) {
      _handleTapDetail();
      return;
    }

    // Determine if drag commits with highly sensitive threshold
    if (distance >= _kSwipeThreshold || speed >= _kFlingVelocityThreshold) {
      _commitSwipe();
    } else {
      _snapBack();
    }
  }

  void _handleTapDetail() {
    if (_deck.isEmpty) return;
    final recipe = _deck.first;
    context.push('/recipes/${recipe.id}?heroTag=deck-${recipe.id}');
  }

  // ── Swipe Commitment & Execution ───────────────────────────────────────────

  void _commitSwipe() {
    if (_deck.isEmpty) return;
    _isAnimating = true;
    HapticFeedback.lightImpact();

    final topRecipe = _deck.first;
    _committedRecipe = topRecipe;
    _committedDirection = _resolveSwipeDirection(_dragOffset, _dragVelocity);

    final screenSize = MediaQuery.sizeOf(context);
    final dx = _dragOffset.dx + (_dragVelocity.dx * 0.25);
    final dy = _dragOffset.dy + (_dragVelocity.dy * 0.25);

    final distance = math.sqrt(dx * dx + dy * dy).clamp(1.0, double.infinity);
    final maxDimension = math.max(screenSize.width, screenSize.height) * 1.6;
    final target = Offset((dx / distance) * maxDimension, (dy / distance) * maxDimension);

    _flyAnimation = Tween<Offset>(
      begin: _dragOffset,
      end: target,
    ).animate(CurvedAnimation(parent: _flyController, curve: Curves.easeOutCubic));

    _flyController.forward(from: 0.0);
  }

  void _onFlyAnimationStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      final direction = _committedDirection;
      final recipe = _committedRecipe;

      if (direction != null && recipe != null && mounted) {
        _executeDirectionAction(direction, recipe);
      }

      setState(() {
        if (_deck.isNotEmpty) {
          final top = _deck.removeAt(0);
          _deck.add(top);
        }
        _dragOffset = Offset.zero;
        _isAnimating = false;
        _committedDirection = null;
        _committedRecipe = null;
      });
      _flyController.reset();
    }
  }

  void _executeDirectionAction(_SwipeDirection direction, Recipe recipe) {
    switch (direction) {
      case _SwipeDirection.right:
        // Save to favorites
        final currentFavs = ref.read(favoritesNotifierProvider).value ?? {};
        if (!currentFavs.contains(recipe.id)) {
          ref.read(favoritesNotifierProvider.notifier).toggleFavorite(recipe.id);
        }
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(
                  Icons.favorite_rounded,
                  color: AppColors.softCoral,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Saved "${recipe.title}" to Favorites!',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
            backgroundColor: const Color(0xFF162D25),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        );
        break;

      case _SwipeDirection.up:
        // Cook Now -> Open recipe detail immediately
        context.push('/recipes/${recipe.id}?heroTag=deck-${recipe.id}');
        break;

      case _SwipeDirection.left:
        // Next dish (pass)
        break;

      case _SwipeDirection.down:
        // Save for later / Snooze
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(
                  Icons.bookmark_added_rounded,
                  color: AppColors.citrusLime,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Snoozed "${recipe.title}" for later cooking',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(milliseconds: 1500),
            backgroundColor: const Color(0xFF162D25),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        );
        break;
    }
  }

  // ── Spring Back ─────────────────────────────────────────────────────────────

  void _snapBack() {
    _isAnimating = true;
    final startOffset = _dragOffset;

    _springController.reset();
    _springAnimation = Tween<Offset>(
      begin: startOffset,
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _springController,
        curve: Curves.easeOutBack,
      ),
    );

    _springController.forward().then((_) {
      if (mounted) {
        setState(() {
          _dragOffset = Offset.zero;
          _isAnimating = false;
        });
      }
    });

    _springController.addListener(() {
      if (mounted && _springAnimation != null) {
        setState(() {
          _dragOffset = _springAnimation!.value;
        });
      }
    });
  }

  // ── Direction Resolution ───────────────────────────────────────────────────

  _SwipeDirection _resolveSwipeDirection(Offset offset, Offset velocity) {
    final dx = offset.dx + (velocity.dx * 0.25);
    final dy = offset.dy + (velocity.dy * 0.25);

    if (dx.abs() > dy.abs()) {
      return dx > 0 ? _SwipeDirection.right : _SwipeDirection.left;
    } else {
      return dy > 0 ? _SwipeDirection.down : _SwipeDirection.up;
    }
  }

  _SwipeDirection? get _activeDirectionHint {
    if (_dragOffset.distance < 12.0) return null;
    return _resolveSwipeDirection(_dragOffset, Offset.zero);
  }

  // ── Computed Front Offset & Rotation ────────────────────────────────────────

  Offset get _frontOffset {
    if (_isAnimating && _flyController.isAnimating) {
      return _flyAnimation.value;
    }
    return _dragOffset;
  }

  double get _frontRotation {
    final dx = _frontOffset.dx;
    return (dx / widget.cardWidth) * 0.20; // Smooth natural rotational glide
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_deck.isEmpty) return const SizedBox.shrink();

    final visibleCount = math.min(_kMaxVisibleDepth, _deck.length);

    return SizedBox(
      width: widget.cardWidth,
      height: widget.cardHeight + _kStackExtraHeight,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          // Back cards (rendered bottom-up for depth)
          for (int i = visibleCount - 1; i >= 1; i--)
            _buildBackCard(depth: i),

          // Interactive Front Card
          _buildFrontCard(),
        ],
      ),
    );
  }

  Widget _buildBackCard({required int depth}) {
    final recipe = _deck[depth % _deck.length];
    final dragProgress = (_dragOffset.distance / 65.0).clamp(0.0, 1.0);

    // Initial resting parameters
    final Offset restingOffset;
    final double restingRotation;
    final double restingScale;
    final double restingOpacity;

    // Target parameters when front card is swiped away
    final Offset targetOffset;
    final double targetRotation;
    final double targetScale;
    final double targetOpacity;

    if (depth == 1) {
      restingOffset = _kBackCard1Offset;
      restingRotation = _kBackCard1Rotation;
      restingScale = _kBackCard1Scale;
      restingOpacity = _kBackCard1Opacity;

      targetOffset = Offset.zero;
      targetRotation = 0.0;
      targetScale = 1.0;
      targetOpacity = 1.0;
    } else {
      restingOffset = _kBackCard2Offset;
      restingRotation = _kBackCard2Rotation;
      restingScale = _kBackCard2Scale;
      restingOpacity = _kBackCard2Opacity;

      targetOffset = _kBackCard1Offset;
      targetRotation = _kBackCard1Rotation;
      targetScale = _kBackCard1Scale;
      targetOpacity = _kBackCard1Opacity;
    }

    final currentOffset = Offset.lerp(restingOffset, targetOffset, dragProgress)!;
    final currentRotation = _lerpDouble(restingRotation, targetRotation, dragProgress);
    final currentScale = _lerpDouble(restingScale, targetScale, dragProgress);
    final currentOpacity = _lerpDouble(restingOpacity, targetOpacity, dragProgress);

    return Transform.translate(
      offset: currentOffset,
      child: Transform.rotate(
        angle: currentRotation,
        child: Transform.scale(
          scale: currentScale,
          child: Opacity(
            opacity: currentOpacity.clamp(0.0, 1.0),
            child: _DeckCardVisual(
              recipe: recipe,
              cardWidth: widget.cardWidth,
              cardHeight: widget.cardHeight,
              isInteractive: false,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFrontCard() {
    final topRecipe = _deck.first;

    return GestureDetector(
      onPanStart: _onPanStart,
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: Listenable.merge([_flyController, _springController]),
        builder: (context, _) {
          return Transform.translate(
            offset: _frontOffset,
            child: Transform.rotate(
              angle: _frontRotation,
              child: Stack(
                children: [
                  _DeckCardVisual(
                    recipe: topRecipe,
                    cardWidth: widget.cardWidth,
                    cardHeight: widget.cardHeight,
                    isInteractive: true,
                  ),
                  // Directional Action Overlay Badge
                  if (_activeDirectionHint != null)
                    _DirectionOverlayBadge(
                      direction: _activeDirectionHint!,
                      opacity: (_dragOffset.distance / 32.0).clamp(0.0, 1.0),
                      cardWidth: widget.cardWidth,
                      cardHeight: widget.cardHeight,
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  double _lerpDouble(double a, double b, double t) => a + (b - a) * t;
}

// ─────────────────────────────────────────────────────────────────────────────
// Card Visual Presentation (Matching Featured Hero Card Elegance)
// ─────────────────────────────────────────────────────────────────────────────

class _DeckCardVisual extends StatelessWidget {
  final Recipe recipe;
  final double cardWidth;
  final double cardHeight;
  final bool isInteractive;

  const _DeckCardVisual({
    required this.recipe,
    required this.cardWidth,
    required this.cardHeight,
    required this.isInteractive,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: cardWidth,
      height: cardHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF173D31).withValues(alpha: 0.28),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background Image with Disk Cache & Fallback
            AppCachedNetworkImage(
              imageUrl: recipe.imageUrl,
              category: recipe.category,
              fit: BoxFit.cover,
              width: cardWidth,
              height: cardHeight,
            ),

            // Rich Dark Gradient Overlay
            Container(
              decoration: const BoxDecoration(
                gradient: AppColors.heroCardOverlay,
              ),
            ),

            // Top Row (Chef's Pick Badge + Favorite Button)
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Glowing Chef's Choice Badge
                  GlassSurface(
                    borderRadius: 20,
                    blur: 14,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    backgroundColor: AppColors.citrusLime.withValues(alpha: 0.90),
                    borderColor: Colors.white.withValues(alpha: 0.60),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.auto_awesome,
                          size: 14,
                          color: AppColors.deepEmerald,
                        ),
                        SizedBox(width: 6),
                        Text(
                          "CHEF'S PICK",
                          style: TextStyle(
                            color: AppColors.deepEmerald,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Favorite Button (Functional on front card)
                  if (isInteractive)
                    FavoriteButton(recipeId: recipe.id)
                  else
                    const SizedBox.shrink(),
                ],
              ),
            ),

            // Bottom Content Glass Panel
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: GlassSurface(
                borderRadius: 20,
                blur: 16,
                padding: const EdgeInsets.all(16),
                backgroundColor: Colors.black.withValues(alpha: 0.48),
                borderColor: Colors.white.withValues(alpha: 0.28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            recipe.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Mini Swipe Guide Pill
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.swipe_rounded,
                                color: Colors.white70,
                                size: 12,
                              ),
                              SizedBox(width: 3),
                              Text(
                                'Swipe',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      recipe.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 10),
                    RecipeMetadataRow(
                      totalMinutes: recipe.totalMinutes,
                      servings: recipe.servings,
                      difficulty: recipe.difficulty,
                      isDarkText: false,
                      prepMinutes: recipe.prepMinutes,
                      cookMinutes: recipe.cookMinutes,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Directional Action Overlay Badge
// ─────────────────────────────────────────────────────────────────────────────

class _DirectionOverlayBadge extends StatelessWidget {
  final _SwipeDirection direction;
  final double opacity;
  final double cardWidth;
  final double cardHeight;

  const _DirectionOverlayBadge({
    required this.direction,
    required this.opacity,
    required this.cardWidth,
    required this.cardHeight,
  });

  @override
  Widget build(BuildContext context) {
    final Color badgeColor;
    final IconData badgeIcon;
    final String badgeLabel;
    final Alignment badgeAlignment;
    final double badgeRotation;

    switch (direction) {
      case _SwipeDirection.right:
        badgeColor = const Color(0xFF2ECC71); // Emerald Green
        badgeIcon = Icons.favorite_rounded;
        badgeLabel = 'SAVE TO FAVORITES';
        badgeAlignment = Alignment.centerLeft;
        badgeRotation = -0.20;
        break;

      case _SwipeDirection.left:
        badgeColor = const Color(0xFFE74C3C); // Soft Coral / Crimson
        badgeIcon = Icons.skip_next_rounded;
        badgeLabel = 'NEXT MEAL';
        badgeAlignment = Alignment.centerRight;
        badgeRotation = 0.20;
        break;

      case _SwipeDirection.up:
        badgeColor = const Color(0xFF3498DB); // Blue / Cyan
        badgeIcon = Icons.restaurant_menu_rounded;
        badgeLabel = 'COOK NOW';
        badgeAlignment = Alignment.topCenter;
        badgeRotation = 0.0;
        break;

      case _SwipeDirection.down:
        badgeColor = const Color(0xFFF39C12); // Amber Orange
        badgeIcon = Icons.bookmark_added_rounded;
        badgeLabel = 'SAVE FOR LATER';
        badgeAlignment = Alignment.bottomCenter;
        badgeRotation = 0.0;
        break;
    }

    return Positioned.fill(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Container(
          color: Colors.black.withValues(alpha: 0.15 * opacity),
          child: Align(
            alignment: badgeAlignment,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Transform.rotate(
                angle: badgeRotation,
                child: Opacity(
                  opacity: opacity.clamp(0.0, 1.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: badgeColor.withValues(alpha: 0.94),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: badgeColor.withValues(alpha: 0.5),
                          blurRadius: 16,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(badgeIcon, color: Colors.white, size: 22),
                        const SizedBox(width: 8),
                        Text(
                          badgeLabel,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
