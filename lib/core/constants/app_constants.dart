class AppConstants {
  static const String appName = 'CookMate';
  static const String appTagline = 'Your personal kitchen companion';

  // Recipe Categories
  static const String categoryQuickAndEasy = 'Quick & Easy';
  static const String categoryHealthyMeals = 'Healthy Meals';
  static const String categoryDesserts = 'Desserts';

  static const List<String> categories = [
    categoryQuickAndEasy,
    categoryHealthyMeals,
    categoryDesserts,
  ];

  // Difficulties
  static const List<String> difficulties = ['Easy', 'Medium', 'Hard'];

  // Breakpoints
  static const double compactBreakpoint = 600.0;
  static const double mediumBreakpoint = 900.0;
  static const double maxContentWidth = 1200.0;

  // Storage Keys
  static const String favoritesStorageKey = 'cookmate_favorite_ids';
  static const String localDraftsKey = 'cookmate_submitted_drafts';

  // Assets
  static const String recipesJsonPath = 'assets/data/recipes.json';
}
