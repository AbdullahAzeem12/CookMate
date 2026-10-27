import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/recipe_repository.dart';
import '../../domain/models/recipe.dart';
import '../../../submission/data/submission_repository.dart';

// Theme Mode Provider (Light/Dark mode switcher)
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.light);

// Repositories
final recipeRepositoryProvider = Provider<RecipeRepository>((ref) {
  return DefaultRecipeRepository();
});

final submissionRepositoryProvider = Provider<RecipeSubmissionRepository>((
  ref,
) {
  return HybridRecipeSubmissionRepository();
});

// All recipes
final allRecipesProvider = FutureProvider<List<Recipe>>((ref) async {
  final repository = ref.watch(recipeRepositoryProvider);
  return repository.getAllRecipes();
});

// Single recipe by ID
final recipeDetailProvider = FutureProvider.family<Recipe?, String>((
  ref,
  id,
) async {
  final repository = ref.watch(recipeRepositoryProvider);
  return repository.getRecipeById(id);
});

// Recipes by category
final recipesByCategoryProvider = FutureProvider.family<List<Recipe>, String>((
  ref,
  category,
) async {
  final repository = ref.watch(recipeRepositoryProvider);
  return repository.getRecipesByCategory(category);
});

// Featured Hero Recipe
final featuredRecipeProvider = Provider<Recipe?>((ref) {
  final allAsync = ref.watch(allRecipesProvider);
  return allAsync.when(
    data: (recipes) => recipes.isNotEmpty ? recipes.first : null,
    loading: () => null,
    error: (_, __) => null,
  );
});

// Search filter state
class SearchFilterState {
  final String query;
  final String category;
  final int? maxCookTime;
  final String sortBy;

  const SearchFilterState({
    this.query = '',
    this.category = 'All',
    this.maxCookTime,
    this.sortBy = 'quickest',
  });

  SearchFilterState copyWith({
    String? query,
    String? category,
    int? maxCookTime,
    String? sortBy,
  }) {
    return SearchFilterState(
      query: query ?? this.query,
      category: category ?? this.category,
      maxCookTime: maxCookTime ?? this.maxCookTime,
      sortBy: sortBy ?? this.sortBy,
    );
  }
}

final searchFilterProvider = StateProvider<SearchFilterState>((ref) {
  return const SearchFilterState();
});

// Search results provider
final searchResultsProvider = FutureProvider<List<Recipe>>((ref) async {
  final repository = ref.watch(recipeRepositoryProvider);
  final filter = ref.watch(searchFilterProvider);

  return repository.searchRecipes(
    query: filter.query,
    category: filter.category == 'All' ? null : filter.category,
    maxCookTime: filter.maxCookTime,
    sortBy: filter.sortBy,
  );
});
