import 'package:cook_mate/features/recipes/domain/models/recipe.dart';
import 'package:cook_mate/features/recipes/domain/services/recipe_scaler.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RecipeScaler Tests', () {
    const testRecipe = Recipe(
      id: 'test-salmon',
      title: 'Pan-Seared Salmon',
      description: 'Crispy skin salmon with asparagus and lemon butter sauce.',
      category: 'Healthy Meals',
      imageUrl: 'https://example.com/salmon.jpg',
      prepMinutes: 10,
      cookMinutes: 15,
      servings: 2,
      difficulty: 'Easy',
      tags: ['Fish', 'Healthy'],
      ingredients: [
        '2 Fresh salmon fillets (180g each, skin-on)',
        '1 bunch Fresh green asparagus, woody ends snapped',
        '2 tbsp Melted grass-fed butter or olive oil',
        '2 cloves Fresh garlic, crushed',
        '1 Lemon, half sliced into wheels and half juiced',
        '1/2 cup Heavy cream',
        '1/4 tsp Crushed chili flakes',
        '250g Rigatoni pasta',
        '1 can (400g) San Marzano crushed tomatoes',
        'Sea salt and freshly cracked black pepper',
      ],
      instructions: ['Prep', 'Cook', 'Serve'],
    );

    test('Scaling factor 1.0 keeps recipe ingredients and times identical', () {
      final scaled = RecipeScaler.scale(recipe: testRecipe, targetServings: 2);

      expect(scaled.servings, 2);
      expect(scaled.prepMinutes, 10);
      expect(scaled.cookMinutes, 15);
      expect(scaled.totalMinutes, 25);
      expect(scaled.ratio, 1.0);
      expect(scaled.ingredients.first.scaled, testRecipe.ingredients.first);
      expect(scaled.ingredients.first.hasChanged, false);
    });

    test('Scaling factor 2.0 (4 servings) intelligently scales quantities, units, and times', () {
      final scaled = RecipeScaler.scale(recipe: testRecipe, targetServings: 4);

      expect(scaled.servings, 4);
      expect(scaled.ratio, 2.0);

      // Times scaled with culinary curves
      expect(scaled.prepMinutes, 14); // 10 * (1 + 0.35) = 13.5 -> 14
      expect(scaled.cookMinutes, 18); // 15 * (1 + 0.20) = 18
      expect(scaled.totalMinutes, 32);

      final ing = scaled.ingredients.map((e) => e.scaled).toList();

      // 2 fillets -> 4 fillets, (180g each) preserved!
      expect(ing[0], '4 Fresh salmon fillets (180g each, skin-on)');
      // 1 bunch -> 2 bunches
      expect(ing[1], '2 bunches Fresh green asparagus, woody ends snapped');
      // 2 tbsp -> 4 tbsp
      expect(ing[2], '4 tbsp Melted grass-fed butter or olive oil');
      // 2 cloves -> 4 cloves
      expect(ing[3], '4 cloves Fresh garlic, crushed');
      // 1 Lemon -> 2 Lemons
      expect(ing[4], '2 Lemons, half sliced into wheels and half juiced');
      // 1/2 cup -> 1 cup
      expect(ing[5], '1 cup Heavy cream');
      // 1/4 tsp -> 1/2 tsp
      expect(ing[6], '1/2 tsp Crushed chili flakes');
      // 250g -> 500g
      expect(ing[7], '500g Rigatoni pasta');
      // 1 can (400g) -> 2 cans (800g)
      expect(ing[8], '2 cans (800g) San Marzano crushed tomatoes');
      // Qualitative ingredient unchanged
      expect(ing[9], 'Sea salt and freshly cracked black pepper');
    });

    test('Scaling factor 0.5 (1 serving) handles singularization and fractions cleanly', () {
      final scaled = RecipeScaler.scale(recipe: testRecipe, targetServings: 1);

      expect(scaled.servings, 1);
      expect(scaled.ratio, 0.5);

      // Times scaled down
      expect(scaled.prepMinutes, 8); // 10 * (1 - 0.175) = 8.25 -> 8
      expect(scaled.cookMinutes, 14); // 15 * (1 - 0.10) = 13.5 -> 14

      final ing = scaled.ingredients.map((e) => e.scaled).toList();

      // 2 fillets -> 1 Fresh salmon fillet
      expect(ing[0], '1 Fresh salmon fillet (180g each, skin-on)');
      // 2 cloves -> 1 clove
      expect(ing[3], '1 clove Fresh garlic, crushed');
      // 1/2 cup -> 1/4 cup
      expect(ing[5], '1/4 cup Heavy cream');
      // 1/4 tsp -> 1/8 tsp
      expect(ing[6], '1/8 tsp Crushed chili flakes');
      // 250g -> 125g
      expect(ing[7], '125g Rigatoni pasta');
      // 1 can (400g) -> 1/2 can (200g)
      expect(ing[8], '1/2 can (200g) San Marzano crushed tomatoes');
    });

    test('formatQuantity formats fractions and whole numbers accurately', () {
      expect(RecipeScaler.formatQuantity(0.25), '1/4');
      expect(RecipeScaler.formatQuantity(0.5), '1/2');
      expect(RecipeScaler.formatQuantity(0.75), '3/4');
      expect(RecipeScaler.formatQuantity(1.0), '1');
      expect(RecipeScaler.formatQuantity(1.5), '1 1/2');
      expect(RecipeScaler.formatQuantity(2.0), '2');
      expect(RecipeScaler.formatQuantity(2.25), '2 1/4');
      expect(RecipeScaler.formatQuantity(250.0), '250');
    });

    test('Special patterns like "2 × 200g A5 Wagyu" and qualitative items scale properly', () {
      const wagyuItem = '2 × 200g A5 Japanese Wagyu striploin steaks';
      expect(
        RecipeScaler.scaleIngredientText(ingredient: wagyuItem, factor: 2.0),
        '4 × 200g A5 Japanese Wagyu striploin steaks',
      );
      expect(
        RecipeScaler.scaleIngredientText(ingredient: wagyuItem, factor: 0.5),
        '1 × 200g A5 Japanese Wagyu striploin steaks',
      );

      const toTaste = 'Sea salt and freshly ground black pepper to taste';
      expect(
        RecipeScaler.scaleIngredientText(ingredient: toTaste, factor: 3.0),
        toTaste,
      );
    });
  });
}
