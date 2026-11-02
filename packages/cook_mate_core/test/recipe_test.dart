import 'package:cook_mate_core/cook_mate_core.dart';
import 'package:test/test.dart';

void main() {
  group('Recipe Model Tests', () {
    test('Correctly parses complete JSON and derives totalMinutes', () {
      final json = {
        'id': 'rec-1',
        'title': 'Pan-Seared Duck Breast',
        'description': 'Crispy duck breast with orange glaze.',
        'category': 'Quick & Easy',
        'imageUrl': 'https://example.com/duck.jpg',
        'ingredients': ['2 duck breasts', '1 orange', '2 tbsp honey'],
        'instructions': ['Score skin', 'Sear skin-down', 'Baste with glaze'],
        'prepMinutes': 15,
        'cookMinutes': 20,
        'servings': 2,
        'difficulty': 'Medium',
        'tags': ['French', 'Duck', 'Dinner'],
        'chefNotes': 'Ensure pan is cold when placing duck breast.',
        'createdAt': '2026-10-27T10:00:00Z',
        'isCommunitySubmission': false,
        'status': 'approved',
        'isChefsPick': true,
      };

      final recipe = Recipe.fromJson(json);

      expect(recipe.id, 'rec-1');
      expect(recipe.title, 'Pan-Seared Duck Breast');
      expect(recipe.totalMinutes, 35);
      expect(recipe.ingredients.length, 3);
      expect(recipe.instructions.length, 3);
      expect(recipe.isChefsPick, true);

      final outMap = recipe.toJson();
      expect(outMap['id'], 'rec-1');
      expect(outMap['servings'], 2);
    });

    test('Gracefully handles missing or null fields with resilient defaults', () {
      final recipe = Recipe.fromJson({});
      expect(recipe.id, '');
      expect(recipe.title, 'Untitled Recipe');
      expect(recipe.servings, 1);
      expect(recipe.prepMinutes, 0);
      expect(recipe.cookMinutes, 0);
      expect(recipe.totalMinutes, 0);
      expect(recipe.ingredients, isEmpty);
      expect(recipe.instructions, isEmpty);
      expect(recipe.status, 'approved');
      expect(recipe.isChefsPick, false);
    });

    test('RecipeParser validates required fields and reports warnings', () {
      const invalidRecipe = Recipe(
        id: 'bad',
        title: '',
        description: '',
        category: 'Quick & Easy',
        imageUrl: '',
        ingredients: [],
        instructions: [],
        prepMinutes: -5,
        cookMinutes: 0,
        servings: 0,
        difficulty: 'Easy',
        tags: [],
      );

      final result = RecipeParser.validate(invalidRecipe);
      expect(result.isValid, false);
      expect(result.errors.length, greaterThanOrEqualTo(4));
      expect(result.warnings.length, greaterThanOrEqualTo(2));
    });
  });
}
