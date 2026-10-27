import 'dart:convert';

import 'package:flutter/services.dart';

import '../../domain/models/recipe.dart';
import '../../../../core/constants/app_constants.dart';

class LocalJsonRecipeDataSource {
  final String assetPath;

  const LocalJsonRecipeDataSource({
    this.assetPath = AppConstants.recipesJsonPath,
  });

  Future<List<Recipe>> loadRecipes() async {
    try {
      final jsonString = await rootBundle.loadString(assetPath);
      final dynamic decoded = jsonDecode(jsonString);

      if (decoded is! List) {
        throw const FormatException(
          'Expected JSON array at root of recipes.json',
        );
      }

      final List<Recipe> recipes = [];
      for (final item in decoded) {
        if (item is Map<String, dynamic>) {
          recipes.add(Recipe.fromJson(item));
        }
      }
      return recipes;
    } catch (e) {
      // Re-throw or return empty with diagnostic
      return [];
    }
  }
}
