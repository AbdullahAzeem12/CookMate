import 'package:cook_mate/features/recipes/domain/models/recipe.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Recipe Model Tests', () {
    test('Correctly parses complete JSON and derives totalMinutes', () {
      final json = {
        'id': 'test-pasta',
        'title': 'Test Tomato Pasta',
        'description': 'Delicious pasta with rich tomato sauce',
        'category': 'Quick & Easy',
        'imageUrl': 'https://example.com/pasta.jpg',
        'ingredients': ['200g Pasta', '1 can Tomatoes', '2 cloves Garlic'],
        'instructions': ['Boil pasta', 'Simmer sauce', 'Combine and serve'],
        'prepMinutes': 10,
        'cookMinutes': 15,
        'servings': 2,
        'difficulty': 'Easy',
        'tags': ['Pasta', 'Quick', 'Italian'],
        'createdAt': '2026-01-15T12:00:00.000Z',
      };

      final recipe = Recipe.fromJson(json);

      expect(recipe.id, 'test-pasta');
      expect(recipe.title, 'Test Tomato Pasta');
      expect(recipe.category, 'Quick & Easy');
      expect(recipe.prepMinutes, 10);
      expect(recipe.cookMinutes, 15);
      expect(recipe.totalMinutes, 25); // 10 + 15
      expect(recipe.servings, 2);
      expect(recipe.ingredients.length, 3);
      expect(recipe.instructions.length, 3);
      expect(recipe.tags, contains('Pasta'));
    });

    test(
      'Gracefully handles missing or null fields with resilient defaults',
      () {
        final json = <String, dynamic>{'id': 'fallback-recipe'};

        final recipe = Recipe.fromJson(json);

        expect(recipe.id, 'fallback-recipe');
        expect(recipe.title, 'Untitled Recipe');
        expect(recipe.prepMinutes, 0);
        expect(recipe.cookMinutes, 0);
        expect(recipe.totalMinutes, 0);
        expect(recipe.servings, 1);
        expect(recipe.ingredients, isEmpty);
        expect(recipe.instructions, isEmpty);
      },
    );

    test('toJson produces valid round-trip map', () {
      const original = Recipe(
        id: 'chocolate-cake',
        title: 'Dark Chocolate Cake',
        description: 'Rich and moist',
        category: 'Desserts',
        imageUrl: 'https://example.com/cake.jpg',
        ingredients: ['Flour', 'Cocoa', 'Sugar'],
        instructions: ['Mix', 'Bake'],
        prepMinutes: 20,
        cookMinutes: 30,
        servings: 8,
        difficulty: 'Medium',
        tags: ['Dessert', 'Baking'],
      );

      final json = original.toJson();
      final reconstituted = Recipe.fromJson(json);

      expect(reconstituted.id, original.id);
      expect(reconstituted.title, original.title);
      expect(reconstituted.totalMinutes, 50);
      expect(reconstituted.difficulty, original.difficulty);
    });
  });
}
