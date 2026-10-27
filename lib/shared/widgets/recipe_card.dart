import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../features/recipes/domain/models/recipe.dart';
import 'favorite_button.dart';
import 'glass_card.dart';
import 'recipe_metadata_row.dart';

class RecipeCard extends StatelessWidget {
  final Recipe recipe;
  final bool isFeatured;
  final VoidCallback? onTap;

  const RecipeCard({
    super.key,
    required this.recipe,
    this.isFeatured = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (isFeatured) {
      return _buildFeaturedCard(context);
    }
    return _buildStandardGridCard(context);
  }

  Widget _buildStandardGridCard(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Semantics(
      label:
          'Recipe ${recipe.title}, ${recipe.category}, ${recipe.totalMinutes} minutes',
      button: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap ?? () => context.push('/recipes/${recipe.id}'),
          borderRadius: BorderRadius.circular(22),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF162D25) : Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.05),
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.2)
                      : const Color(0xFF173D31).withValues(alpha: 0.06),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final hasBoundedHeight = constraints.hasBoundedHeight;

                final imageWidget = Stack(
                  fit: hasBoundedHeight ? StackFit.expand : StackFit.loose,
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(22),
                      ),
                      child: hasBoundedHeight
                          ? SizedBox.expand(
                              child: Hero(
                                tag: 'recipe-image-${recipe.id}',
                                child: _buildNetworkImage(recipe.imageUrl),
                              ),
                            )
                          : AspectRatio(
                              aspectRatio: 1.35,
                              child: Hero(
                                tag: 'recipe-image-${recipe.id}',
                                child: _buildNetworkImage(recipe.imageUrl),
                              ),
                            ),
                    ),
                    // Category chip overlay
                    Positioned(
                      top: 8,
                      left: 8,
                      child: GlassSurface(
                        borderRadius: 16,
                        blur: 10,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        backgroundColor: Colors.black.withValues(alpha: 0.4),
                        borderColor: Colors.white.withValues(alpha: 0.2),
                        child: Text(
                          recipe.category,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    // Favorite button
                    Positioned(
                      top: 6,
                      right: 6,
                      child: FavoriteButton(recipeId: recipe.id, size: 18),
                    ),
                  ],
                );

                final detailsWidget = Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        recipe.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 5),
                      RecipeMetadataRow(
                        totalMinutes: recipe.totalMinutes,
                        servings: recipe.servings,
                        difficulty: recipe.difficulty,
                        isDarkText: true,
                      ),
                    ],
                  ),
                );

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (hasBoundedHeight)
                      Expanded(child: imageWidget)
                    else
                      imageWidget,
                    detailsWidget,
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturedCard(BuildContext context) {
    return Semantics(
      label: 'Featured Recipe ${recipe.title}, ${recipe.category}',
      button: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap ?? () => context.push('/recipes/${recipe.id}'),
          borderRadius: BorderRadius.circular(28),
          child: Container(
            height: 320,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF173D31).withValues(alpha: 0.25),
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
                  // Background Hero Image
                  Hero(
                    tag: 'recipe-image-${recipe.id}',
                    child: _buildNetworkImage(recipe.imageUrl),
                  ),
                  // Rich Dark Gradient Overlay
                  Container(
                    decoration: const BoxDecoration(
                      gradient: AppColors.heroCardOverlay,
                    ),
                  ),
                  // Top Row (Badge + Favorite)
                  Positioned(
                    top: 16,
                    left: 16,
                    right: 16,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GlassSurface(
                          borderRadius: 20,
                          blur: 14,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 6,
                          ),
                          backgroundColor: AppColors.citrusLime.withValues(
                            alpha: 0.85,
                          ),
                          borderColor: Colors.white.withValues(alpha: 0.5),
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
                        FavoriteButton(recipeId: recipe.id),
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
                      backgroundColor: Colors.black.withValues(alpha: 0.45),
                      borderColor: Colors.white.withValues(alpha: 0.25),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            recipe.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            recipe.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.82),
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
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNetworkImage(String url) {
    if (url.isEmpty) {
      return _buildImagePlaceholder();
    }

    return Image.network(
      url,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          color: const Color(0xFF1E352C),
          child: Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                  : null,
              color: AppColors.citrusLime,
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return _buildImagePlaceholder();
      },
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF173D31), Color(0xFF2C5547)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.restaurant_menu_rounded,
              size: 36,
              color: AppColors.citrusLime.withValues(alpha: 0.8),
            ),
            const SizedBox(height: 6),
            Text(
              recipe.category,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
