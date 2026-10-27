import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/favorites_repository.dart';
import '../../../recipes/domain/models/recipe.dart';
import '../../../recipes/presentation/providers/recipe_providers.dart';

final favoritesRepositoryProvider = Provider<FavoritesRepository>((ref) {
  return LocalFavoritesRepository();
});

class FavoritesNotifier extends AsyncNotifier<Set<String>> {
  @override
  Future<Set<String>> build() async {
    final repository = ref.read(favoritesRepositoryProvider);
    return repository.getFavoriteIds();
  }

  Future<void> toggleFavorite(String recipeId) async {
    final repository = ref.read(favoritesRepositoryProvider);
    final previousState = state.value ?? <String>{};
    final isFav = previousState.contains(recipeId);

    // Optimistic update
    final newSet = isFav
        ? previousState.where((id) => id != recipeId).toSet()
        : {...previousState, recipeId};
    state = AsyncData(newSet);

    try {
      if (isFav) {
        await repository.removeFavorite(recipeId);
      } else {
        await repository.addFavorite(recipeId);
      }
    } catch (e) {
      // Rollback on failure
      state = AsyncData(previousState);
    }
  }

  Future<void> clearAll() async {
    final repository = ref.read(favoritesRepositoryProvider);
    state = const AsyncData(<String>{});
    try {
      await repository.clearFavorites();
    } catch (_) {
      ref.invalidateSelf();
    }
  }
}

final favoritesNotifierProvider =
    AsyncNotifierProvider<FavoritesNotifier, Set<String>>(
      FavoritesNotifier.new,
    );

// Favorite recipes list resolved against all recipes
final favoriteRecipesProvider = Provider<AsyncValue<List<Recipe>>>((ref) {
  final allRecipesAsync = ref.watch(allRecipesProvider);
  final favoriteIdsAsync = ref.watch(favoritesNotifierProvider);

  if (allRecipesAsync is AsyncLoading || favoriteIdsAsync is AsyncLoading) {
    return const AsyncLoading();
  }

  if (allRecipesAsync is AsyncError) {
    return AsyncError(allRecipesAsync.error!, allRecipesAsync.stackTrace!);
  }

  final allRecipes = allRecipesAsync.value ?? [];
  final favoriteIds = favoriteIdsAsync.value ?? <String>{};

  final matching = allRecipes.where((r) => favoriteIds.contains(r.id)).toList();
  return AsyncData(matching);
});
