import 'package:cook_mate/features/recipes/data/datasources/local_json_recipe_data_source.dart';
import 'package:cook_mate/features/recipes/data/repositories/recipe_repository.dart';
import 'package:cook_mate/features/recipes/domain/models/recipe.dart';
import 'package:cook_mate/features/submission/data/submission_repository.dart';
import 'package:flutter_test/flutter_test.dart';

class MockLocalDataSource implements LocalJsonRecipeDataSource {
  @override
  String get assetPath => 'test_asset';

  @override
  Future<List<Recipe>> loadRecipes() async {
    return [
      const Recipe(
        id: 'pasta-1',
        title: 'Classic Tomato Pasta',
        description: 'Rich tomato sauce with fresh basil',
        category: 'Quick & Easy',
        imageUrl: '',
        ingredients: ['Rigatoni', 'Tomato sauce', 'Garlic'],
        instructions: ['Boil pasta', 'Simmer sauce'],
        prepMinutes: 5,
        cookMinutes: 10,
        servings: 2,
        difficulty: 'Easy',
        tags: ['Pasta', 'Italian'],
      ),
      const Recipe(
        id: 'salad-1',
        title: 'Greek Quinoa Salad',
        description: 'Fresh vegetables and feta cheese',
        category: 'Healthy Meals',
        imageUrl: '',
        ingredients: ['Quinoa', 'Cucumber', 'Feta'],
        instructions: ['Chop vegetables', 'Toss with olive oil'],
        prepMinutes: 15,
        cookMinutes: 0,
        servings: 4,
        difficulty: 'Easy',
        tags: ['Salad', 'Healthy', 'Vegetarian'],
      ),
      const Recipe(
        id: 'cake-1',
        title: 'Molten Chocolate Cake',
        description: 'Warm oozing dark chocolate center',
        category: 'Desserts',
        imageUrl: '',
        ingredients: ['Dark chocolate', 'Butter', 'Eggs'],
        instructions: ['Melt chocolate', 'Bake in ramekins'],
        prepMinutes: 20,
        cookMinutes: 25,
        servings: 2,
        difficulty: 'Medium',
        tags: ['Chocolate', 'Dessert'],
      ),
    ];
  }
}

class MockSubmissionRepository implements RecipeSubmissionRepository {
  List<Recipe> drafts = [];

  @override
  Future<SubmissionResult> submitRecipe(Recipe recipe) async {
    drafts.add(recipe);
    return SubmissionResult(
      success: true,
      isSavedToCloud: false,
      isSavedLocally: true,
      recipe: recipe,
      message: 'Saved locally',
    );
  }

  @override
  Future<List<Recipe>> getLocalSubmittedDrafts() async => drafts;
}

void main() {
  group('DefaultRecipeRepository Tests', () {
    late DefaultRecipeRepository repository;
    late MockLocalDataSource mockLocal;
    late MockSubmissionRepository mockSubmission;

    setUp(() {
      mockLocal = MockLocalDataSource();
      mockSubmission = MockSubmissionRepository();
      repository = DefaultRecipeRepository(
        localDataSource: mockLocal,
        submissionRepository: mockSubmission,
      );
    });

    test('getAllRecipes returns bundled recipes', () async {
      final recipes = await repository.getAllRecipes();
      expect(recipes.length, 3);
      expect(recipes.first.id, 'pasta-1');
    });

    test('getRecipesByCategory filters correctly', () async {
      final healthy = await repository.getRecipesByCategory('Healthy Meals');
      expect(healthy.length, 1);
      expect(healthy.first.id, 'salad-1');

      final desserts = await repository.getRecipesByCategory('Desserts');
      expect(desserts.length, 1);
      expect(desserts.first.id, 'cake-1');
    });

    test(
      'searchRecipes matches keywords in title, ingredients, and tags',
      () async {
        // Title match
        final byTitle = await repository.searchRecipes(query: 'chocolate');
        expect(byTitle.length, 1);
        expect(byTitle.first.id, 'cake-1');

        // Ingredient match
        final byIngredient = await repository.searchRecipes(query: 'cucumber');
        expect(byIngredient.length, 1);
        expect(byIngredient.first.id, 'salad-1');

        // Tag match
        final byTag = await repository.searchRecipes(query: 'Italian');
        expect(byTag.length, 1);
        expect(byTag.first.id, 'pasta-1');
      },
    );

    test(
      'searchRecipes filters by maxCookTime and sorts by quickest',
      () async {
        final results = await repository.searchRecipes(
          query: '',
          maxCookTime: 12, // only salad (0m) and pasta (10m)
          sortBy: 'quickest',
        );

        expect(results.length, 2);
        expect(results.first.id, 'pasta-1'); // total 15m vs salad 15m
      },
    );

    test('addSubmittedRecipe adds to cache and overrides duplicates', () async {
      const newRecipe = Recipe(
        id: 'user-tacos',
        title: 'Street Style Fish Tacos',
        description: 'Crispy fish with chipotle crema',
        category: 'Quick & Easy',
        imageUrl: '',
        ingredients: ['Fish', 'Tortillas', 'Cabbage'],
        instructions: ['Fry fish', 'Assemble tacos'],
        prepMinutes: 10,
        cookMinutes: 10,
        servings: 2,
        difficulty: 'Easy',
        tags: ['Mexican', 'Tacos'],
      );

      await repository.addSubmittedRecipe(newRecipe);

      final all = await repository.getAllRecipes();
      expect(all.any((r) => r.id == 'user-tacos'), isTrue);
    });
  });
}
