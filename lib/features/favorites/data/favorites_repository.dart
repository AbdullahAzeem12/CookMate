import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/app_constants.dart';

abstract interface class FavoritesRepository {
  Future<Set<String>> getFavoriteIds();
  Future<void> addFavorite(String recipeId);
  Future<void> removeFavorite(String recipeId);
  Future<void> clearFavorites();
}

class LocalFavoritesRepository implements FavoritesRepository {
  final SharedPreferences? _injectedPrefs;

  LocalFavoritesRepository({SharedPreferences? prefs}) : _injectedPrefs = prefs;

  Future<SharedPreferences> _getPrefs() async {
    if (_injectedPrefs != null) return _injectedPrefs;
    return SharedPreferences.getInstance();
  }

  @override
  Future<Set<String>> getFavoriteIds() async {
    try {
      final prefs = await _getPrefs();
      final list = prefs.getStringList(AppConstants.favoritesStorageKey);
      return (list ?? []).toSet();
    } catch (_) {
      return <String>{};
    }
  }

  @override
  Future<void> addFavorite(String recipeId) async {
    if (recipeId.trim().isEmpty) return;
    final prefs = await _getPrefs();
    final current = await getFavoriteIds();
    final updated = {...current, recipeId};
    await prefs.setStringList(
      AppConstants.favoritesStorageKey,
      updated.toList(),
    );
  }

  @override
  Future<void> removeFavorite(String recipeId) async {
    final prefs = await _getPrefs();
    final current = await getFavoriteIds();
    final updated = current.where((id) => id != recipeId).toList();
    await prefs.setStringList(AppConstants.favoritesStorageKey, updated);
  }

  @override
  Future<void> clearFavorites() async {
    final prefs = await _getPrefs();
    await prefs.remove(AppConstants.favoritesStorageKey);
  }
}
