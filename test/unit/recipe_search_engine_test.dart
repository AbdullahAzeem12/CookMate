import 'package:cook_mate/features/recipes/domain/models/recipe.dart';
import 'package:cook_mate/features/recipes/domain/services/recipe_search_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RecipeSearchEngine Tests', () {
    const frenchMacarons = Recipe(
      id: 'french-macarons',
      title: 'French Pâtisserie Raspberry Rose Macarons',
      description: 'Artisanal Parisian macaron shells with delicate ruffled feet.',
      category: 'Desserts',
      imageUrl: '',
      ingredients: ['Almond flour', 'Powdered sugar', 'Egg whites'],
      instructions: ['Fold batter', 'Bake with steam'],
      prepMinutes: 60,
      cookMinutes: 18,
      servings: 12,
      difficulty: 'Hard',
      tags: ['French', 'French Pastry', 'Baking'],
    );

    const frenchOnionSoup = Recipe(
      id: 'french-onion-soup',
      title: 'Classic French Onion Soup Gratinée',
      description: 'Caramelized sweet yellow onions simmered in beef bone broth.',
      category: 'Healthy Meals',
      imageUrl: '',
      ingredients: ['Yellow onions', 'Beef broth', 'French baguette', 'Gruyère'],
      instructions: ['Caramelize onions', 'Simmer broth', 'Broil cheese'],
      prepMinutes: 15,
      cookMinutes: 45,
      servings: 4,
      difficulty: 'Medium',
      tags: ['French', 'Soup', 'Classic'],
    );

    const frenchSouffle = Recipe(
      id: 'grand-marnier-souffle',
      title: 'Classic French Grand Marnier Orange Soufflé',
      description: 'A cloud-light French dessert soufflé that rises over two inches.',
      category: 'Desserts',
      imageUrl: '',
      ingredients: ['Milk', 'Egg yolks', 'Grand Marnier cognac liqueur'],
      instructions: ['Make pastry cream', 'Whip egg whites', 'Bake'],
      prepMinutes: 35,
      cookMinutes: 18,
      servings: 4,
      difficulty: 'Hard',
      tags: ['French', 'Soufflé', 'Dessert'],
    );

    const tomatoOmelette = Recipe(
      id: 'tomato-omelette',
      title: 'Rustic Garden Tomato & Herb Omelette',
      description: 'French-style fluffy eggs folded over blistered sweet cherry tomatoes.',
      category: 'Quick & Easy',
      imageUrl: '',
      ingredients: ['Eggs', 'Cherry tomatoes', '1 tbsp French unsalted butter'],
      instructions: ['Whisk eggs', 'Cook omelette'],
      prepMinutes: 5,
      cookMinutes: 7,
      servings: 1,
      difficulty: 'Easy',
      tags: ['Breakfast', 'Eggs', 'Quick'],
    );

    const sampleRecipes = [
      tomatoOmelette,
      frenchMacarons,
      frenchOnionSoup,
      frenchSouffle,
    ];

    test('normalize removes diacritics and special characters correctly', () {
      expect(RecipeSearchEngine.normalize('Pâtisserie'), 'patisserie');
      expect(RecipeSearchEngine.normalize('Soufflé'), 'souffle');
      expect(RecipeSearchEngine.normalize('Crêpe & Fondant!'), 'crepe fondant');
      expect(RecipeSearchEngine.normalize('  Mirepoix   au  Jus  '), 'mirepoix au jus');
    });

    test('Query "fren" ranks dishes with French in title above dishes with French only in ingredients', () {
      final results = RecipeSearchEngine.search(
        recipes: sampleRecipes,
        query: 'fren',
        sortBy: 'relevance',
      );

      expect(results.length, 4);

      // Top result must have title starting with French
      expect(results.first.id, 'french-macarons');

      // The second and third result must have French in the title
      final top3Ids = results.take(3).map((r) => r.id).toList();
      expect(top3Ids, contains('french-macarons'));
      expect(top3Ids, contains('french-onion-soup'));
      expect(top3Ids, contains('grand-marnier-souffle'));

      // The omelette (which only mentions French in ingredients/description) must be last
      expect(results.last.id, 'tomato-omelette');
    });

    test('Query with accents works both with and without accent', () {
      // Searching "souffle" without accent
      final searchUnaccented = RecipeSearchEngine.search(
        recipes: sampleRecipes,
        query: 'souffle',
      );
      expect(searchUnaccented.length, 1);
      expect(searchUnaccented.first.id, 'grand-marnier-souffle');

      // Searching "soufflé" with accent
      final searchAccented = RecipeSearchEngine.search(
        recipes: sampleRecipes,
        query: 'soufflé',
      );
      expect(searchAccented.length, 1);
      expect(searchAccented.first.id, 'grand-marnier-souffle');
    });

    test('Multi-token query requires all tokens to be present', () {
      // "french soup" must match French Onion Soup, but NOT French Macarons
      final results = RecipeSearchEngine.search(
        recipes: sampleRecipes,
        query: 'french soup',
      );
      expect(results.length, 1);
      expect(results.first.id, 'french-onion-soup');
    });

    test('Prefix query matches incrementally as user types letters', () {
      final rF = RecipeSearchEngine.search(recipes: sampleRecipes, query: 'f');
      final rFr = RecipeSearchEngine.search(recipes: sampleRecipes, query: 'fr');
      final rFre = RecipeSearchEngine.search(recipes: sampleRecipes, query: 'fre');
      final rFren = RecipeSearchEngine.search(recipes: sampleRecipes, query: 'fren');

      expect(rF.isNotEmpty, isTrue);
      expect(rFr.isNotEmpty, isTrue);
      expect(rFre.isNotEmpty, isTrue);
      expect(rFren.isNotEmpty, isTrue);

      // In all stages, French title dishes rank at the top
      expect(rFren.first.id, 'french-macarons');
    });

    test('Category filter works with search query', () {
      final dessertsOnly = RecipeSearchEngine.search(
        recipes: sampleRecipes,
        query: 'french',
        category: 'Desserts',
      );
      expect(dessertsOnly.length, 2);
      expect(dessertsOnly.every((r) => r.category == 'Desserts'), isTrue);
    });

    test('Sorting by quickest orders by totalMinutes', () {
      final quickest = RecipeSearchEngine.search(
        recipes: sampleRecipes,
        query: '',
        sortBy: 'quickest',
      );
      // tomatoOmelette: 5 + 7 = 12m
      // frenchSouffle: 35 + 18 = 53m
      // frenchOnionSoup: 15 + 45 = 60m
      // frenchMacarons: 60 + 18 = 78m
      expect(quickest.first.id, 'tomato-omelette');
      expect(quickest.last.id, 'french-macarons');
    });

    test('Sorting by title orders alphabetically (A-Z)', () {
      final byTitle = RecipeSearchEngine.search(
        recipes: sampleRecipes,
        query: '',
        sortBy: 'title',
      );
      final titles = byTitle.map((r) => r.title).toList();
      final sortedTitles = List<String>.from(titles)..sort();
      expect(titles, sortedTitles);
    });
  });
}

