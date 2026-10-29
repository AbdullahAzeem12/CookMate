import 'package:flutter_test/flutter_test.dart';
import 'package:cook_mate/core/constants/app_constants.dart';
import 'package:cook_mate/features/submission/domain/services/smart_recipe_autofill_service.dart';

void main() {
  group('SmartRecipeAutofillService Tests', () {
    test('Analyzes "Red valvet Cake" with "Desserts" category and returns authentic recipe details', () {
      final suggestion = SmartRecipeAutofillService.generateSuggestion(
        title: 'Red valvet Cake',
        categoryHint: 'Desserts',
      );

      // Verify category and title
      expect(suggestion.category, equals(AppConstants.categoryDesserts));
      expect(suggestion.title.toLowerCase(), contains('red valvet'));

      // Verify authentic Unsplash photo URL
      expect(suggestion.imageUrl, startsWith('https://images.unsplash.com/'));
      expect(suggestion.imageUrl, contains('photo-1586788680434-30d324b2d46f'));

      // Verify cooking & prep times
      expect(suggestion.prepMinutes, equals(25));
      expect(suggestion.cookMinutes, equals(35));
      expect(suggestion.servings, equals(10));
      expect(suggestion.difficulty, equals('Medium'));

      // Verify authentic ingredients
      expect(suggestion.ingredients.length, greaterThanOrEqualTo(8));
      expect(
        suggestion.ingredients.any((i) => i.toLowerCase().contains('cocoa')),
        isTrue,
      );
      expect(
        suggestion.ingredients.any((i) => i.toLowerCase().contains('cream cheese')),
        isTrue,
      );
      expect(
        suggestion.ingredients.any((i) => i.toLowerCase().contains('buttermilk')),
        isTrue,
      );

      // Verify step-by-step instructions
      expect(suggestion.instructions.length, greaterThanOrEqualTo(5));
      expect(
        suggestion.instructions.any((step) => step.toLowerCase().contains('350°f')),
        isTrue,
      );
      expect(
        suggestion.instructions.any((step) => step.toLowerCase().contains('cream cheese')),
        isTrue,
      );
    });

    test('Correctly identifies and populates other signature dishes (Lasagna, Biryani, Avocado Toast)', () {
      // Lasagna
      final lasagna = SmartRecipeAutofillService.generateSuggestion(
        title: 'Lasagna',
      );
      expect(lasagna.category, equals(AppConstants.categoryQuickAndEasy));
      expect(lasagna.imageUrl, contains('photo-1574894709920-11b28e7367e3'));
      expect(lasagna.ingredients.any((i) => i.toLowerCase().contains('ricotta')), isTrue);

      // Biryani
      final biryani = SmartRecipeAutofillService.generateSuggestion(
        title: 'Chicken Biryani',
      );
      expect(biryani.imageUrl, contains('photo-1563379091339-03b21ab4a4f8'));
      expect(biryani.ingredients.any((i) => i.toLowerCase().contains('basmati')), isTrue);

      // Avocado Toast
      final toast = SmartRecipeAutofillService.generateSuggestion(
        title: 'Avocado Toast',
      );
      expect(toast.category, equals(AppConstants.categoryHealthyMeals));
      expect(toast.imageUrl, contains('photo-1525351484163-7529414344d8'));
      expect(toast.prepMinutes, equals(8));
    });

    test('Infers Desserts category for sweet keywords and generates valid gourmet details', () {
      final suggestion = SmartRecipeAutofillService.generateSuggestion(
        title: 'Pistachio Strawberry Tart',
      );
      expect(suggestion.category, equals(AppConstants.categoryDesserts));
      expect(suggestion.prepMinutes, greaterThan(0));
      expect(suggestion.cookMinutes, greaterThan(0));
      expect(suggestion.ingredients.length, greaterThanOrEqualTo(5));
      expect(suggestion.instructions.length, greaterThanOrEqualTo(4));
    });

    test('Infers Healthy Meals category for greens and healthy keywords', () {
      final suggestion = SmartRecipeAutofillService.generateSuggestion(
        title: 'Crispy Kale Quinoa Superbowl',
      );
      expect(suggestion.category, equals(AppConstants.categoryHealthyMeals));
      expect(suggestion.imageUrl, startsWith('https://images.unsplash.com/'));
      expect(suggestion.difficulty, equals('Easy'));
    });
  });
}

