import 'dart:convert';

import '../models/recipe.dart';

/// Validation report containing errors and warnings for a [Recipe].
class RecipeValidationResult {
  final bool isValid;
  final List<String> errors;
  final List<String> warnings;

  const RecipeValidationResult({
    required this.isValid,
    required this.errors,
    required this.warnings,
  });

  @override
  String toString() =>
      'RecipeValidationResult(valid: $isValid, errors: ${errors.length}, warnings: ${warnings.length})';
}

/// Parsing and validation utilities for recipe data.
class RecipeParser {
  const RecipeParser._();

  /// Parses a JSON string containing either a single recipe object or a list of recipes.
  static List<Recipe> parseJsonString(String rawJson) {
    if (rawJson.trim().isEmpty) return const [];
    try {
      final decoded = jsonDecode(rawJson);
      return parseDecodedJson(decoded);
    } catch (_) {
      return const [];
    }
  }

  /// Parses a dynamically decoded JSON structure into a list of [Recipe] instances.
  static List<Recipe> parseDecodedJson(dynamic decoded) {
    if (decoded is List) {
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(Recipe.fromJson)
          .toList();
    } else if (decoded is Map<String, dynamic>) {
      // Check if wrapper key exists (e.g. {"recipes": [...]})
      if (decoded['recipes'] is List) {
        return (decoded['recipes'] as List)
            .whereType<Map<String, dynamic>>()
            .map(Recipe.fromJson)
            .toList();
      }
      return [Recipe.fromJson(decoded)];
    }
    return const [];
  }

  /// Validates a [Recipe] against culinary standards and completeness criteria.
  static RecipeValidationResult validate(Recipe recipe) {
    final List<String> errors = [];
    final List<String> warnings = [];

    if (recipe.title.trim().isEmpty) {
      errors.add('Recipe title cannot be empty.');
    }
    if (recipe.ingredients.isEmpty) {
      errors.add('Recipe must have at least one ingredient.');
    }
    if (recipe.instructions.isEmpty) {
      errors.add('Recipe must have at least one instruction step.');
    }
    if (recipe.servings <= 0) {
      errors.add('Servings must be greater than zero.');
    }
    if (recipe.prepMinutes < 0) {
      errors.add('Prep minutes cannot be negative.');
    }
    if (recipe.cookMinutes < 0) {
      errors.add('Cook minutes cannot be negative.');
    }

    if (recipe.description.trim().isEmpty) {
      warnings.add('Recipe description is empty.');
    }
    if (recipe.imageUrl.trim().isEmpty) {
      warnings.add('Recipe image URL is missing.');
    }
    if (recipe.tags.isEmpty) {
      warnings.add('Recipe has no tags/cuisines assigned.');
    }

    return RecipeValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
    );
  }
}
