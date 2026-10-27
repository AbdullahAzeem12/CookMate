import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/recipe_providers.dart';
import '../../../../shared/widgets/category_chip.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/recipe_card.dart';
import '../../../../shared/widgets/shimmer_loading.dart';

class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({super.key});

  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen> {
  String _selectedCategory = 'All';
  String _sortBy = 'quickest'; // 'quickest', 'prep', 'title'

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final allRecipesAsync = ref.watch(allRecipesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Explore Recipes',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          // Sort Menu
          PopupMenuButton<String>(
            tooltip: 'Sort recipes',
            icon: Icon(
              Icons.swap_vert_rounded,
              color: isDark ? AppColors.citrusLime : AppColors.forestGreen,
            ),
            initialValue: _sortBy,
            onSelected: (val) {
              setState(() => _sortBy = val);
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'quickest',
                child: Row(
                  children: [
                    Icon(Icons.bolt_rounded, size: 18),
                    SizedBox(width: 8),
                    Text('Shortest Cook Time'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'prep',
                child: Row(
                  children: [
                    Icon(Icons.timer_outlined, size: 18),
                    SizedBox(width: 8),
                    Text('Prep Time'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'title',
                child: Row(
                  children: [
                    Icon(Icons.sort_by_alpha_rounded, size: 18),
                    SizedBox(width: 8),
                    Text('Name (A-Z)'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Category Filter Pills Row
            Container(
              height: 48,
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  CategoryChip(
                    label: 'All',
                    isSelected: _selectedCategory == 'All',
                    onTap: () => setState(() => _selectedCategory = 'All'),
                  ),
                  ...AppConstants.categories.map(
                    (cat) => CategoryChip(
                      label: cat,
                      isSelected: _selectedCategory == cat,
                      onTap: () => setState(() => _selectedCategory = cat),
                    ),
                  ),
                ],
              ),
            ),

            // Matching count & Sort label
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: allRecipesAsync.when(
                      data: (recipes) {
                        final filtered = _filterAndSort(recipes);
                        return Text(
                          '${filtered.length} dishes available',
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        );
                      },
                      loading: () => const Text('Loading recipes...'),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _sortBy == 'quickest'
                        ? 'Quickest'
                        : _sortBy == 'prep'
                        ? 'Prep Time'
                        : 'Alphabetical',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.citrusLime
                          : AppColors.forestGreen,
                    ),
                  ),
                ],
              ),
            ),

            // Recipe Grid
            Expanded(
              child: allRecipesAsync.when(
                data: (recipes) {
                  final filtered = _filterAndSort(recipes);
                  if (filtered.isEmpty) {
                    return EmptyState(
                      icon: Icons.search_off_rounded,
                      title: 'No recipes found',
                      message: 'Try selecting a different category filter.',
                      actionLabel: 'Reset to All',
                      onAction: () => setState(() => _selectedCategory = 'All'),
                    );
                  }

                  return GridView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 280,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio: 0.76,
                        ),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      return RecipeCard(recipe: filtered[index]);
                    },
                  );
                },
                loading: () => GridView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 280,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 0.76,
                  ),
                  itemCount: 6,
                  itemBuilder: (_, __) => const RecipeCardSkeleton(),
                ),
                error: (err, _) =>
                    Center(child: Text('Failed to load recipes: $err')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<dynamic> _filterAndSort(List<dynamic> list) {
    var result = list.where((r) {
      if (_selectedCategory == 'All') return true;
      return r.category.toLowerCase() == _selectedCategory.toLowerCase();
    }).toList();

    if (_sortBy == 'quickest') {
      result.sort((a, b) => a.totalMinutes.compareTo(b.totalMinutes));
    } else if (_sortBy == 'prep') {
      result.sort((a, b) => a.prepMinutes.compareTo(b.prepMinutes));
    } else if (_sortBy == 'title') {
      result.sort((a, b) => a.title.compareTo(b.title));
    }

    return result;
  }
}
