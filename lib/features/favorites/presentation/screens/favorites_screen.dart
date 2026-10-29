import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../providers/favorites_providers.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/recipe_card.dart';
import '../../../../shared/widgets/shimmer_loading.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  void _showClearConfirmDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear All Favorites?'),
        content: const Text(
          'Are you sure you want to remove all saved recipes from your collection?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.softCoral,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              ref.read(favoritesNotifierProvider.notifier).clearAll();
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Favorites collection cleared.'),
                  backgroundColor: AppColors.forestGreen,
                ),
              );
            },
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final favoriteRecipesAsync = ref.watch(favoriteRecipesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Saved Recipes',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          favoriteRecipesAsync.when(
            data: (recipes) {
              if (recipes.isEmpty) return const SizedBox.shrink();
              return IconButton(
                tooltip: 'Clear all favorites',
                icon: const Icon(Icons.delete_sweep_rounded),
                onPressed: () => _showClearConfirmDialog(context, ref),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        bottom: false,
        child: favoriteRecipesAsync.when(
          data: (recipes) {
            if (recipes.isEmpty) {
              return EmptyState(
                icon: Icons.bookmark_border_rounded,
                title: 'No saved recipes yet',
                message: 'Tap the heart icon on any recipe to save your favorite dishes here for quick cooking.',
                actionLabel: 'Discover Recipes',
                onAction: () => context.go('/recipes'),
                showLogo: true,
              );
            }

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${recipes.length} saved recipes',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color:
                                (isDark
                                        ? AppColors.citrusLime
                                        : AppColors.forestGreen)
                                    .withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Offline Ready',
                            style: TextStyle(
                              color: isDark
                                  ? AppColors.citrusLime
                                  : AppColors.forestGreen,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 280,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio: 0.70,
                        ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => RecipeCard(
                        recipe: recipes[index],
                        heroTagPrefix: 'fav',
                      ),
                      childCount: recipes.length,
                    ),
                  ),
                ),
              ],
            );
          },
          loading: () => GridView.builder(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 280,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 0.70,
            ),
            itemCount: 4,
            itemBuilder: (_, __) => const RecipeCardSkeleton(),
          ),
          error: (err, _) =>
              Center(child: Text('Failed to load favorites: $err')),
        ),
      ),
    );
  }
}
