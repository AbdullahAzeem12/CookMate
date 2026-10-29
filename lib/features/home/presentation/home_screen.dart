import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/presentation/providers/auth_providers.dart';
import '../../auth/presentation/widgets/chef_avatar_view.dart';
import '../../recipes/presentation/providers/recipe_providers.dart';
import '../../../shared/widgets/app_logo_badge.dart';
import '../../../shared/widgets/bounce_tap.dart';
import '../../../shared/widgets/category_chip.dart';
import '../../../shared/widgets/chef_pick_deck.dart';
import '../../../shared/widgets/glass_search_bar.dart';
import '../../../shared/widgets/recipe_card.dart';
import '../../../shared/widgets/shimmer_loading.dart';
import '../../../shared/widgets/trending_recipe_slider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  String _getTimeGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final allRecipesAsync = ref.watch(allRecipesProvider);
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: AppColors.forestGreen,
          onRefresh: () async {
            ref.invalidate(allRecipesProvider);
          },
          child: CustomScrollView(
            slivers: [
              // Top Editorial Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            const AppLogoBadge(
                              size: 46,
                              margin: EdgeInsets.only(right: 12),
                            ),
                            Flexible(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          '${_getTimeGreeting()}, Chef',
                                          overflow: TextOverflow.ellipsis,
                                          style: theme.textTheme.bodyMedium?.copyWith(
                                            fontWeight: FontWeight.w600,
                                            color: isDark
                                                ? AppColors.citrusLime
                                                : AppColors.forestGreen,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      const Text('✨', style: TextStyle(fontSize: 14)),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    AppConstants.appName,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.displayMedium?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Theme Switcher & Profile Avatar
                      Row(
                        children: [
                          IconButton(
                            tooltip: isDark
                                ? 'Switch to Light'
                                : 'Switch to Dark',
                            icon: Icon(
                              isDark
                                  ? Icons.light_mode_rounded
                                  : Icons.dark_mode_rounded,
                              color: isDark
                                  ? AppColors.citrusLime
                                  : AppColors.forestGreen,
                            ),
                            onPressed: () {
                              ref.read(themeModeProvider.notifier).state =
                                  isDark ? ThemeMode.light : ThemeMode.dark;
                            },
                          ),
                          const SizedBox(width: 4),
                          BounceTap(
                            onTap: () => context.push('/profile'),
                            child: ChefAvatarView(
                              avatarUrl: currentUser?.avatarUrl,
                              name: currentUser != null
                                  ? (currentUser.name.isNotEmpty
                                      ? currentUser.name
                                      : '👨‍🍳')
                                  : '👨‍🍳',
                              size: 52,
                              borderRadius: 15,
                              isEditable: false,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Search bar leading to /search
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  child: GlassSearchBar(
                    readOnly: true,
                    hintText: 'Search dishes, ingredients, tags...',
                    onTap: () => context.push('/search'),
                    onFilterTap: () => context.push('/search'),
                  ),
                ),
              ),

              // Category Quick Filters
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Categories',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          BounceTap(
                            onTap: () => context.go('/recipes'),
                            shrinkScale: 0.90,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              child: Text(
                                'See all',
                                style: TextStyle(
                                  color: isDark
                                      ? AppColors.citrusLime
                                      : AppColors.forestGreen,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: 44,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        children: [
                          CategoryChip(
                            label: 'All Dishes',
                            icon: Icons.restaurant_rounded,
                            isSelected: false,
                            onTap: () => context.go('/recipes'),
                          ),
                          CategoryChip(
                            label: 'Quick & Easy',
                            icon: Icons.bolt_rounded,
                            isSelected: false,
                            onTap: () {
                              ref
                                  .read(searchFilterProvider.notifier)
                                  .state = const SearchFilterState(
                                category: 'Quick & Easy',
                              );
                              context.go('/recipes');
                            },
                          ),
                          CategoryChip(
                            label: 'Healthy Meals',
                            icon: Icons.eco_rounded,
                            isSelected: false,
                            onTap: () {
                              ref
                                  .read(searchFilterProvider.notifier)
                                  .state = const SearchFilterState(
                                category: 'Healthy Meals',
                              );
                              context.go('/recipes');
                            },
                          ),
                          CategoryChip(
                            label: 'Desserts',
                            icon: Icons.cake_rounded,
                            isSelected: false,
                            onTap: () {
                              ref.read(searchFilterProvider.notifier).state =
                                  const SearchFilterState(category: 'Desserts');
                              context.go('/recipes');
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ── Featured Chef's Choice Swipable Deck (Hero Slot) ───────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: allRecipesAsync.when(
                    data: (recipes) {
                      if (recipes.isEmpty) return const SizedBox.shrink();
                      return const ChefPickDeck();
                    },
                    loading: () => const RecipeCardSkeleton(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                ),
              ),

              // Trending Recipes Section Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                'Trending Recipes',
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.softCoral.withValues(
                                  alpha: 0.18,
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text(
                                'HOT',
                                style: TextStyle(
                                  color: AppColors.softCoral,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      BounceTap(
                        onTap: () => context.go('/recipes'),
                        shrinkScale: 0.90,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          child: Text(
                            'View All',
                            style: TextStyle(
                              color: isDark
                                  ? AppColors.citrusLime
                                  : AppColors.forestGreen,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Trending Recipes Horizontal Slider with Pop-in/out and Fade-in/out
              SliverToBoxAdapter(
                child: allRecipesAsync.when(
                  data: (recipes) {
                    final trending = recipes.skip(1).take(12).toList();
                    return TrendingRecipeSlider(recipes: trending);
                  },
                  loading: () => SizedBox(
                    height: 265,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: 3,
                      separatorBuilder: (_, __) => const SizedBox(width: 14),
                      itemBuilder: (_, __) => const SizedBox(
                        width: 208,
                        child: RecipeCardSkeleton(),
                      ),
                    ),
                  ),
                  error: (err, _) => Center(child: Text('Error: $err')),
                ),
              ),

              // Chef's Selection / Healthy Section Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                  child: Text(
                    'Editor’s Selection',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),

              // Responsive Recipe Grid
              allRecipesAsync.when(
                data: (recipes) {
                  final editorList = recipes.skip(6).toList();
                  return SliverPadding(
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
                          recipe: editorList[index],
                          heroTagPrefix: 'home-grid',
                        ),
                        childCount: editorList.length,
                      ),
                    ),
                  );
                },
                loading: () => SliverPadding(
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
                      (context, index) => const RecipeCardSkeleton(),
                      childCount: 4,
                    ),
                  ),
                ),
                error: (err, _) => SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text('Failed to load recipes: $err'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
