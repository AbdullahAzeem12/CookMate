import '../datasources/local_json_recipe_data_source.dart';
import '../../domain/models/recipe.dart';
import '../../../submission/data/submission_repository.dart';

abstract interface class RecipeRepository {
  Future<List<Recipe>> getAllRecipes();
  Future<Recipe?> getRecipeById(String id);
  Future<List<Recipe>> getRecipesByCategory(String category);
  Future<List<Recipe>> searchRecipes({
    required String query,
    String? category,
    int? maxCookTime,
    String? sortBy, // 'quickest', 'prep', 'title'
  });
  Future<void> addSubmittedRecipe(Recipe recipe);
}

class DefaultRecipeRepository implements RecipeRepository {
  final LocalJsonRecipeDataSource _localDataSource;
  final RecipeSubmissionRepository _submissionRepository;

  List<Recipe>? _cachedRecipes;

  DefaultRecipeRepository({
    LocalJsonRecipeDataSource? localDataSource,
    RecipeSubmissionRepository? submissionRepository,
  }) : _localDataSource = localDataSource ?? const LocalJsonRecipeDataSource(),
       _submissionRepository =
           submissionRepository ?? HybridRecipeSubmissionRepository();

  @override
  Future<List<Recipe>> getAllRecipes() async {
    if (_cachedRecipes != null) {
      return _cachedRecipes!;
    }

    final bundled = await _localDataSource.loadRecipes();
    final localDrafts = await _submissionRepository.getLocalSubmittedDrafts();

    // Combine and deduplicate by ID with submitted taking precedence
    final Map<String, Recipe> map = {};
    for (final r in bundled) {
      map[r.id] = r;
    }
    for (final s in localDrafts) {
      map[s.id] = s;
    }

    _cachedRecipes = map.values.toList();
    return _cachedRecipes!;
  }

  @override
  Future<Recipe?> getRecipeById(String id) async {
    final all = await getAllRecipes();
    try {
      return all.firstWhere((r) => r.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<Recipe>> getRecipesByCategory(String category) async {
    final all = await getAllRecipes();
    if (category == 'All' || category.isEmpty) {
      return all;
    }
    return all
        .where((r) => r.category.toLowerCase() == category.toLowerCase())
        .toList();
  }

  @override
  Future<List<Recipe>> searchRecipes({
    required String query,
    String? category,
    int? maxCookTime,
    String? sortBy,
  }) async {
    final all = await getAllRecipes();
    final cleanQuery = query.trim().toLowerCase();

    var results = all.where((recipe) {
      // 1. Query match against title, ingredients, tags, or description
      final matchesQuery =
          cleanQuery.isEmpty ||
          recipe.title.toLowerCase().contains(cleanQuery) ||
          recipe.description.toLowerCase().contains(cleanQuery) ||
          recipe.tags.any((tag) => tag.toLowerCase().contains(cleanQuery)) ||
          recipe.ingredients.any(
            (ing) => ing.toLowerCase().contains(cleanQuery),
          );

      if (!matchesQuery) return false;

      // 2. Category match
      if (category != null && category.isNotEmpty && category != 'All') {
        if (recipe.category.toLowerCase() != category.toLowerCase()) {
          return false;
        }
      }

      // 3. Max cook time filter
      if (maxCookTime != null && maxCookTime > 0) {
        if (recipe.cookMinutes > maxCookTime) {
          return false;
        }
      }

      return true;
    }).toList();

    // Sorting
    if (sortBy == 'quickest') {
      results.sort((a, b) => a.totalMinutes.compareTo(b.totalMinutes));
    } else if (sortBy == 'prep') {
      results.sort((a, b) => a.prepMinutes.compareTo(b.prepMinutes));
    } else if (sortBy == 'title') {
      results.sort((a, b) => a.title.compareTo(b.title));
    }

    return results;
  }

  @override
  Future<void> addSubmittedRecipe(Recipe recipe) async {
    final all = await getAllRecipes();
    final updated = [recipe, ...all.where((r) => r.id != recipe.id)];
    _cachedRecipes = updated;
  }
}
