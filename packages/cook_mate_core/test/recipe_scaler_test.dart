import 'package:cook_mate_core/cook_mate_core.dart';
import 'package:test/test.dart';

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

      expect(scaled.prepMinutes, 14);
      expect(scaled.cookMinutes, 18);
      expect(scaled.totalMinutes, 32);

      final ing = scaled.ingredients.map((e) => e.scaled).toList();

      expect(ing[0], '4 Fresh salmon fillets (180g each, skin-on)');
      expect(ing[1], '2 bunches Fresh green asparagus, woody ends snapped');
      expect(ing[2], '4 tbsp Melted grass-fed butter or olive oil');
      expect(ing[3], '4 cloves Fresh garlic, crushed');
      expect(ing[4], '2 Lemons, half sliced into wheels and half juiced');
      expect(ing[5], '1 cup Heavy cream');
      expect(ing[6], '1/2 tsp Crushed chili flakes');
      expect(ing[7], '500g Rigatoni pasta');
      expect(ing[8], '2 cans (800g) San Marzano crushed tomatoes');
      expect(ing[9], 'Sea salt and freshly cracked black pepper');
    });

    test('Scaling factor 0.5 (1 serving) handles singularization and fractions cleanly', () {
      final scaled = RecipeScaler.scale(recipe: testRecipe, targetServings: 1);

      expect(scaled.servings, 1);
      expect(scaled.ratio, 0.5);

      expect(scaled.prepMinutes, 8);
      expect(scaled.cookMinutes, 14);

      final ing = scaled.ingredients.map((e) => e.scaled).toList();

      expect(ing[0], '1 Fresh salmon fillet (180g each, skin-on)');
      expect(ing[3], '1 clove Fresh garlic, crushed');
      expect(ing[5], '1/4 cup Heavy cream');
      expect(ing[6], '1/8 tsp Crushed chili flakes');
      expect(ing[7], '125g Rigatoni pasta');
    });

    test('formatQuantity formats fractions and whole numbers accurately', () {
      expect(RecipeScaler.formatQuantity(0.5), '1/2');
      expect(RecipeScaler.formatQuantity(0.25), '1/4');
      expect(RecipeScaler.formatQuantity(0.75), '3/4');
      expect(RecipeScaler.formatQuantity(1.5), '1 1/2');
      expect(RecipeScaler.formatQuantity(2.333), '2 1/3');
      expect(RecipeScaler.formatQuantity(4.0), '4');
    });

    test('Special patterns like "2 × 200g A5 Wagyu" scale properly', () {
      const wagyu = '2 × 200g A5 Wagyu striploin';
      final scaled = RecipeScaler.scaleIngredientText(ingredient: wagyu, factor: 3.0);
      expect(scaled, '6 × 200g A5 Wagyu striploin');
    });
  });
}
