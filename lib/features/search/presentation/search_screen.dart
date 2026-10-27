import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../recipes/presentation/providers/recipe_providers.dart';
import '../../../../shared/widgets/category_chip.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/glass_search_bar.dart';
import '../../../../shared/widgets/recipe_card.dart';
import '../../../../shared/widgets/shimmer_loading.dart';

class SearchScreen extends ConsumerStatefulWidget {
  final String? initialQuery;

  const SearchScreen({super.key, this.initialQuery});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  late TextEditingController _searchController;
  int? _maxCookTime;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialQuery ?? '');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
        ref
            .read(searchFilterProvider.notifier)
            .update((s) => s.copyWith(query: widget.initialQuery!));
      }
    });
  }

  @override
  void didUpdateWidget(covariant SearchScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialQuery != oldWidget.initialQuery &&
        widget.initialQuery != null) {
      _searchController.text = widget.initialQuery!;
      ref
          .read(searchFilterProvider.notifier)
          .update((s) => s.copyWith(query: widget.initialQuery!));
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onQueryChanged(String query) {
    ref
        .read(searchFilterProvider.notifier)
        .update((s) => s.copyWith(query: query));
  }

  void _selectCategory(String cat) {
    ref
        .read(searchFilterProvider.notifier)
        .update((s) => s.copyWith(category: cat));
  }

  void _setMaxCookTime(int? minutes) {
    setState(() => _maxCookTime = minutes);
    ref
        .read(searchFilterProvider.notifier)
        .update((s) => s.copyWith(maxCookTime: minutes));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filterState = ref.watch(searchFilterProvider);
    final searchResultsAsync = ref.watch(searchResultsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Find a Dish',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Input Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Hero(
                tag: 'main-search-bar',
                child: Material(
                  color: Colors.transparent,
                  child: GlassSearchBar(
                    controller: _searchController,
                    onChanged: _onQueryChanged,
                    hintText: 'Search title, garlic, pasta, vegan...',
                    showFilterButton: false,
                  ),
                ),
              ),
            ),

            // Category Filter Pills
            Container(
              height: 44,
              margin: const EdgeInsets.only(top: 8, bottom: 4),
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  CategoryChip(
                    label: 'All',
                    isSelected: filterState.category == 'All',
                    onTap: () => _selectCategory('All'),
                  ),
                  ...AppConstants.categories.map(
                    (cat) => CategoryChip(
                      label: cat,
                      isSelected: filterState.category == cat,
                      onTap: () => _selectCategory(cat),
                    ),
                  ),
                ],
              ),
            ),

            // Cook Time Quick Filter Pills
            Container(
              height: 40,
              margin: const EdgeInsets.only(bottom: 12),
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  _buildTimeFilterChip('Any Cook Time', null),
                  _buildTimeFilterChip('⚡ ≤ 10 min', 10),
                  _buildTimeFilterChip('🕒 ≤ 20 min', 20),
                  _buildTimeFilterChip('⏳ ≤ 35 min', 35),
                ],
              ),
            ),

            // Search Results Heading
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              child: searchResultsAsync.when(
                data: (results) => Text(
                  '${results.length} recipes matched',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                loading: () => const Text('Searching culinary archive...'),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ),

            // Results List / Grid
            Expanded(
              child: searchResultsAsync.when(
                data: (recipes) {
                  if (recipes.isEmpty) {
                    return EmptyState(
                      icon: Icons.search_off_rounded,
                      title: 'No recipes matched',
                      message: _searchController.text.isNotEmpty
                          ? 'We couldn\'t find any dish matching "${_searchController.text}".'
                          : 'Try searching for an ingredient, dish, or category.',
                      actionLabel: 'Clear Search',
                      onAction: () {
                        _searchController.clear();
                        _onQueryChanged('');
                        _selectCategory('All');
                        _setMaxCookTime(null);
                      },
                    );
                  }

                  return GridView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 280,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio: 0.70,
                        ),
                    itemCount: recipes.length,
                    itemBuilder: (context, index) {
                      return RecipeCard(recipe: recipes[index]);
                    },
                  );
                },
                loading: () => GridView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 280,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 0.70,
                  ),
                  itemCount: 4,
                  itemBuilder: (_, __) => const RecipeCardSkeleton(),
                ),
                error: (err, _) => Center(child: Text('Search error: $err')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeFilterChip(String label, int? minutes) {
    final isSelected = _maxCookTime == minutes;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => _setMaxCookTime(minutes),
        backgroundColor: isDark ? const Color(0xFF162D25) : Colors.white,
        selectedColor: isDark ? AppColors.citrusLime : AppColors.forestGreen,
        labelStyle: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          color: isSelected
              ? (isDark ? AppColors.deepEmerald : Colors.white)
              : (isDark ? AppColors.textLight : AppColors.textDark),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isSelected
                ? Colors.transparent
                : (isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.06)),
          ),
        ),
      ),
    );
  }
}
