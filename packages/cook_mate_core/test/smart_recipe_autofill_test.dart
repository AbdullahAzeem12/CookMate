import 'package:cook_mate_core/cook_mate_core.dart';
import 'package:test/test.dart';

void main() {
  group('SmartRecipeAutofillService Tests', () {
    test('Analyzes "Red valvet Cake" with "Desserts" category and returns authentic recipe details', () {
      final suggestion = SmartRecipeAutofillService.generateSuggestion(
        title: 'Red valvet Cake',
        categoryHint: 'Desserts',
      );

      expect(suggestion.category, equals(CookMateConstants.categoryDesserts));
      expect(suggestion.title.toLowerCase(), contains('red valvet'));
      expect(suggestion.imageUrl, startsWith('https://images.unsplash.com/'));
      expect(suggestion.imageUrl, contains('photo-1586788680434-30d324b2d46f'));

      expect(suggestion.prepMinutes, equals(25));
      expect(suggestion.cookMinutes, equals(35));
      expect(suggestion.servings, equals(10));
      expect(suggestion.difficulty, equals('Medium'));

      expect(suggestion.ingredients.length, greaterThanOrEqualTo(8));
      expect(
        suggestion.ingredients.any((i) => i.toLowerCase().contains('cocoa')),
        isTrue,
      );
      expect(
        suggestion.ingredients.any((i) => i.toLowerCase().contains('cream cheese')),
        isTrue,
      );

      expect(suggestion.instructions.length, greaterThanOrEqualTo(5));
      expect(
        suggestion.instructions.any((step) => step.toLowerCase().contains('350°f')),
        isTrue,
      );
    });

    test('Correctly identifies and populates other signature dishes (Lasagna, Biryani, Avocado Toast)', () {
      final lasagna = SmartRecipeAutofillService.generateSuggestion(
        title: 'Lasagna',
      );
      expect(lasagna.category, equals(CookMateConstants.categoryQuickAndEasy));
      expect(lasagna.imageUrl, contains('photo-1574894709920-11b28e7367e3'));

      final biryani = SmartRecipeAutofillService.generateSuggestion(
        title: 'Chicken Biryani',
      );
      expect(biryani.imageUrl, contains('photo-1563379091339-03b21ab4a4f8'));

      final toast = SmartRecipeAutofillService.generateSuggestion(
        title: 'Avocado Toast',
      );
      expect(toast.category, equals(CookMateConstants.categoryHealthyMeals));
      expect(toast.imageUrl, contains('photo-1525351484163-7529414344d8'));
    });

    test('Infers Desserts category for sweet keywords and generates valid gourmet details', () {
      final suggestion = SmartRecipeAutofillService.generateSuggestion(
        title: 'Pistachio Strawberry Tart',
      );
      expect(suggestion.category, equals(CookMateConstants.categoryDesserts));
      expect(suggestion.prepMinutes, greaterThan(0));
      expect(suggestion.cookMinutes, greaterThan(0));
      expect(suggestion.ingredients.length, greaterThanOrEqualTo(5));
      expect(suggestion.instructions.length, greaterThanOrEqualTo(4));
    });

    test('Infers Healthy Meals category for greens and healthy keywords', () {
      final suggestion = SmartRecipeAutofillService.generateSuggestion(
        title: 'Crispy Kale Quinoa Superbowl',
      );
      expect(suggestion.category, equals(CookMateConstants.categoryHealthyMeals));
      expect(suggestion.imageUrl, startsWith('https://images.unsplash.com/'));
      expect(suggestion.difficulty, equals('Easy'));
    });
  });
}
