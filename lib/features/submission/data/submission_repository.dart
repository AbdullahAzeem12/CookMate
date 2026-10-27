import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../recipes/domain/models/recipe.dart';
import '../../../../core/constants/app_constants.dart';

class SubmissionResult {
  final bool success;
  final bool isSavedToCloud;
  final bool isSavedLocally;
  final Recipe recipe;
  final String message;
  final String? error;

  const SubmissionResult({
    required this.success,
    required this.isSavedToCloud,
    required this.isSavedLocally,
    required this.recipe,
    required this.message,
    this.error,
  });
}

abstract interface class RecipeSubmissionRepository {
  Future<SubmissionResult> submitRecipe(Recipe recipe);
  Future<List<Recipe>> getLocalSubmittedDrafts();
}

class HybridRecipeSubmissionRepository implements RecipeSubmissionRepository {
  final SharedPreferences? _injectedPrefs;

  HybridRecipeSubmissionRepository({SharedPreferences? prefs})
    : _injectedPrefs = prefs;

  Future<SharedPreferences> _getPrefs() async {
    if (_injectedPrefs != null) return _injectedPrefs;
    return SharedPreferences.getInstance();
  }

  @override
  Future<SubmissionResult> submitRecipe(Recipe recipe) async {
    bool savedToCloud = false;
    bool savedLocally = false;
    String? cloudError;

    // 1. Check if Firebase is initialized and attempt Firestore write
    try {
      if (Firebase.apps.isNotEmpty) {
        final firestore = FirebaseFirestore.instance;
        final docRef = firestore
            .collection('recipe_submissions')
            .doc(recipe.id);

        await docRef
            .set({
              'id': recipe.id,
              'title': recipe.title,
              'description': recipe.description,
              'category': recipe.category,
              'imageUrl': recipe.imageUrl,
              'ingredients': recipe.ingredients,
              'instructions': recipe.instructions,
              'prepMinutes': recipe.prepMinutes,
              'cookMinutes': recipe.cookMinutes,
              'servings': recipe.servings,
              'difficulty': recipe.difficulty,
              'tags': recipe.tags,
              'status': 'pending', // Security: strictly pending
              'authorUid': recipe.authorUid ?? 'anonymous_chef',
              'createdAt': FieldValue.serverTimestamp(),
              'isCommunitySubmission': true,
            })
            .timeout(const Duration(seconds: 8));

        savedToCloud = true;
      } else {
        cloudError = 'Firebase not initialized (running offline mode).';
      }
    } catch (e) {
      cloudError = e.toString();
    }

    // 2. Persist locally as active submission/draft
    try {
      final prefs = await _getPrefs();
      final existingDrafts = await getLocalSubmittedDrafts();
      final updatedDrafts = [
        ...existingDrafts.where((r) => r.id != recipe.id),
        recipe.copyWith(
          isCommunitySubmission: true,
          status: savedToCloud ? 'pending' : 'local_draft',
        ),
      ];

      final encoded = jsonEncode(updatedDrafts.map((r) => r.toJson()).toList());
      await prefs.setString(AppConstants.localDraftsKey, encoded);
      savedLocally = true;
    } catch (_) {
      // Local save issue
    }

    final success = savedToCloud || savedLocally;
    final message = savedToCloud
        ? 'Recipe submitted successfully to Cloud Firestore! Pending moderation.'
        : savedLocally
        ? 'Recipe saved locally as draft (offline mode).'
        : 'Failed to save recipe: ${cloudError ?? "Unknown storage error"}';

    return SubmissionResult(
      success: success,
      isSavedToCloud: savedToCloud,
      isSavedLocally: savedLocally,
      recipe: recipe.copyWith(
        isCommunitySubmission: true,
        status: savedToCloud ? 'pending' : 'local_draft',
      ),
      message: message,
      error: cloudError,
    );
  }

  @override
  Future<List<Recipe>> getLocalSubmittedDrafts() async {
    try {
      final prefs = await _getPrefs();
      final raw = prefs.getString(AppConstants.localDraftsKey);
      if (raw == null || raw.trim().isEmpty) return [];

      final dynamic decoded = jsonDecode(raw);
      if (decoded is! List) return [];

      return decoded
          .whereType<Map<String, dynamic>>()
          .map((m) => Recipe.fromJson(m))
          .toList();
    } catch (_) {
      return [];
    }
  }
}
