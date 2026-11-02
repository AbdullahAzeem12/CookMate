/// Represents an ingredient that has been dynamically scaled for a specific serving size.
class ScaledIngredient {
  /// The unscaled original ingredient text.
  final String original;

  /// The scaled ingredient text with adjusted quantity and pluralization.
  final String scaled;

  /// Whether the ingredient quantity or wording was altered during scaling.
  final bool hasChanged;

  const ScaledIngredient({
    required this.original,
    required this.scaled,
    required this.hasChanged,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScaledIngredient &&
          runtimeType == other.runtimeType &&
          original == other.original &&
          scaled == other.scaled &&
          hasChanged == other.hasChanged;

  @override
  int get hashCode => original.hashCode ^ scaled.hashCode ^ hasChanged.hashCode;

  @override
  String toString() =>
      'ScaledIngredient(original: "$original", scaled: "$scaled", changed: $hasChanged)';
}

/// Contains all dynamically scaled attributes of a recipe for a target serving count.
class ScaledRecipeInfo {
  /// The target number of servings scaled for.
  final int servings;

  /// Recalculated prep minutes adhering to sub-linear culinary efficiency.
  final int prepMinutes;

  /// Recalculated cook minutes adhering to batch thermal mass curves.
  final int cookMinutes;

  /// Total cooking time (prepMinutes + cookMinutes).
  final int totalMinutes;

  /// Multiplier ratio (targetServings / baseServings).
  final double ratio;

  /// The list of scaled ingredients.
  final List<ScaledIngredient> ingredients;

  const ScaledRecipeInfo({
    required this.servings,
    required this.prepMinutes,
    required this.cookMinutes,
    required this.totalMinutes,
    required this.ratio,
    required this.ingredients,
  });

  @override
  String toString() =>
      'ScaledRecipeInfo(servings: $servings, prep: ${prepMinutes}m, cook: ${cookMinutes}m, ratio: $ratio)';
}
