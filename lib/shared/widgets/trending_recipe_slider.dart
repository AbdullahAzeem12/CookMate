import 'package:flutter/material.dart';

import '../../features/recipes/domain/models/recipe.dart';
import 'recipe_card.dart';

/// A fluid, responsive horizontal slider for trending recipes featuring real-time
/// "pop in / pop out" (scaling) and "fade in / fade out" (opacity) dynamic transitions
/// as cards slide across the viewport.
class TrendingRecipeSlider extends StatefulWidget {
  final List<Recipe> recipes;
  final double cardWidth;
  final double cardHeight;
  final double itemSpacing;
  final EdgeInsetsGeometry padding;

  const TrendingRecipeSlider({
    super.key,
    required this.recipes,
    this.cardWidth = 208.0,
    this.cardHeight = 265.0,
    this.itemSpacing = 14.0,
    this.padding = const EdgeInsets.symmetric(horizontal: 20),
  });

  @override
  State<TrendingRecipeSlider> createState() => _TrendingRecipeSliderState();
}

class _TrendingRecipeSliderState extends State<TrendingRecipeSlider> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.recipes.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: widget.cardHeight,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final viewportWidth = constraints.maxWidth;
          final paddingLeft =
              widget.padding.resolve(Directionality.of(context)).left;
          final focalRadius = (viewportWidth * 0.55).clamp(180.0, 500.0);

          return ListView.separated(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            padding: widget.padding,
            itemCount: widget.recipes.length,
            separatorBuilder: (_, __) =>
                SizedBox(width: widget.itemSpacing),
            itemBuilder: (context, index) {
              final recipe = widget.recipes[index];

              return AnimatedBuilder(
                animation: _scrollController,
                builder: (context, child) {
                  final scrollOffset = _scrollController.hasClients &&
                          _scrollController.positions.length == 1
                      ? _scrollController.offset
                      : 0.0;
                  final viewportCenter = scrollOffset + (viewportWidth / 2);

                  // Calculate exact center position of this card in scroll coordinates
                  final cardLeft = paddingLeft +
                      index * (widget.cardWidth + widget.itemSpacing);
                  final cardCenter = cardLeft + (widget.cardWidth / 2);

                  // Normalized distance from viewport center: 0.0 = centered, 1.0 = edge/beyond
                  final distanceFromCenter =
                      (cardCenter - viewportCenter).abs();
                  final progress =
                      (distanceFromCenter / focalRadius).clamp(0.0, 1.0);

                  // Smooth quadratic ease for fluid pop/fade transitions
                  final eased = Curves.easeOutQuad.transform(progress);

                  // Pop In (1.02) when centered, Pop Out (0.88) when moving towards edges
                  final scale = 1.02 - (1.02 - 0.88) * eased;

                  // Fade In (1.00) when centered, Fade Out (0.68) when moving towards edges
                  final opacity =
                      (1.00 - (1.00 - 0.68) * eased).clamp(0.0, 1.0);

                  // Subtle vertical depth translation (+6px when popped out)
                  final translateY = 6.0 * eased;

                  return SizedBox(
                    width: widget.cardWidth,
                    height: widget.cardHeight,
                    child: Transform.translate(
                      offset: Offset(0, translateY),
                      child: Transform.scale(
                        scale: scale,
                        child: Opacity(
                          opacity: opacity,
                          child: child,
                        ),
                      ),
                    ),
                  );
                },
                child: RecipeCard(
                  recipe: recipe,
                  heroTagPrefix: 'home-trend',
                ),
              );
            },
          );
        },
      ),
    );
  }
}

