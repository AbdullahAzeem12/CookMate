// ignore_for_file: avoid_print

import 'package:cook_mate_core/cook_mate_core.dart';

void main() {
  print('=== CookMate Core Demonstration ===\n');

  // 1. Define a recipe
  const recipe = Recipe(
    id: 'wagyu-steak',
    title: 'A5 Wagyu Striploin with Truffle Butter',
    description: 'Ultra-luxurious Japanese Wagyu seared with rosemary and truffle butter.',
    category: CookMateConstants.categoryQuickAndEasy,
    imageUrl: 'https://images.unsplash.com/photo-1544025162-d76694265947',
    ingredients: [
      '2 × 200g A5 Wagyu striploin steaks',
      '2 tbsp Clarified butter',
      '3 Sprigs fresh rosemary',
      '4 Cloves garlic, crushed',
      '30g Black truffle butter',
      'Sea salt and freshly ground black pepper to taste',
    ],
    instructions: [
      'Bring steaks to room temperature 30 minutes before cooking.',
      'Generously season all sides with sea salt.',
      'Sear steaks in smoking-hot cast iron skillet for 2 minutes per side.',
      'Baste with butter, crushed garlic, and rosemary.',
      'Rest for 5 minutes before slicing.',
    ],
    prepMinutes: 10,
    cookMinutes: 8,
    servings: 2,
    difficulty: 'Medium',
    tags: ['Steak', 'Gourmet', 'Dinner'],
  );

  // 2. Scale up from 2 to 6 servings (3x factor)
  print('Original recipe for ${recipe.servings} servings:');
  for (final ing in recipe.ingredients) {
    print('  - $ing');
  }

  print('\nDynamically scaling to 6 servings (3x):');
  final scaled = RecipeScaler.scale(recipe: recipe, targetServings: 6);
  print('Target Servings: ${scaled.servings}');
  print('Adjusted Prep Time: ${scaled.prepMinutes} minutes (sub-linear efficiency)');
  print('Adjusted Cook Time: ${scaled.cookMinutes} minutes (batch thermal curve)');
  print('Scaled Ingredients:');
  for (final ing in scaled.ingredients) {
    print('  - ${ing.scaled}');
  }

  // 3. Unit Conversion
  print('\nUnit Conversions:');
  final oz = UnitConverter.gramsToOunces(200);
  print('200g steak in ounces: ${oz.toStringAsFixed(1)} oz');

  final fahrenheit = UnitConverter.celsiusToFahrenheit(220);
  print('220°C oven in Fahrenheit: ${fahrenheit.round()}°F');

  // 4. Diacritic-Agnostic Search
  print('\nSearch Engine Query:');
  const query = 'wagyu strip';
  final score = RecipeSearchEngine.calculateScore(recipe, query);
  print('Query "$query" matched with score: $score');

  // 5. Chef AI Autofill
  print('\nChef AI Recipe Inference:');
  final suggestion = SmartRecipeAutofillService.generateSuggestion(
    title: 'Red Velvet Cake',
  );
  print('Suggested Dish: ${suggestion.title}');
  print('Category: ${suggestion.category}');
  print('Prep: ${suggestion.prepMinutes}m | Cook: ${suggestion.cookMinutes}m');
  print('Generated Ingredients Count: ${suggestion.ingredients.length}');
  print('Generated Instructions Count: ${suggestion.instructions.length}');
}
