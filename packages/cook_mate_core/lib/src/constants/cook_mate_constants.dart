/// Standard culinary categories, difficulties, and default values.
class CookMateConstants {
  const CookMateConstants._();

  static const String categoryQuickAndEasy = 'Quick & Easy';
  static const String categoryHealthyMeals = 'Healthy Meals';
  static const String categoryDesserts = 'Desserts';

  /// Standard culinary categories
  static const List<String> defaultCategories = [
    categoryQuickAndEasy,
    categoryHealthyMeals,
    categoryDesserts,
  ];

  /// Standard difficulty levels
  static const List<String> difficulties = ['Easy', 'Medium', 'Hard'];

  /// Default serving size
  static const int defaultServings = 4;
}
