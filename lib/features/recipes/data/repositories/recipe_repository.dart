import '../datasources/local_json_recipe_data_source.dart';
import '../../domain/models/recipe.dart';
import '../../domain/services/recipe_search_engine.dart';
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

    // User submissions and community creations take top priority and appear first
    final submittedIds = localDrafts.map((s) => s.id).toSet();
    final remainingBundled =
        bundled.where((b) => !submittedIds.contains(b.id)).toList();

    _cachedRecipes = [...localDrafts.reversed, ...remainingBundled];
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
    return RecipeSearchEngine.search(
      recipes: all,
      query: query,
      category: category,
      maxCookTime: maxCookTime,
      sortBy: sortBy,
    );
  }

  @override
  Future<void> addSubmittedRecipe(Recipe recipe) async {
    final all = await getAllRecipes();
    final updated = [recipe, ...all.where((r) => r.id != recipe.id)];
    _cachedRecipes = updated;
  }
}
