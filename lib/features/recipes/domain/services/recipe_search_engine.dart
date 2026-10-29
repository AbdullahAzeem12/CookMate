import '../../domain/models/recipe.dart';

/// Intelligent relevance scorer and ranking engine for culinary recipes.
/// Provides high-precision exact prefix matching, multi-token resolution,
/// diacritic normalization, and cuisine/ingredient relevance ranking.
class RecipeSearchEngine {
  const RecipeSearchEngine();

  /// Normalizes a string by converting to lowercase, stripping diacritics (accents),
  /// removing punctuation, and collapsing multiple spaces into a single space.
  static String normalize(String input) {
    return input
        .toLowerCase()
        .replaceAll(RegExp(r'[àáâãäå]'), 'a')
        .replaceAll(RegExp(r'[èéêë]'), 'e')
        .replaceAll(RegExp(r'[ìíîï]'), 'i')
        .replaceAll(RegExp(r'[òóôõö]'), 'o')
        .replaceAll(RegExp(r'[ùúûü]'), 'u')
        .replaceAll(RegExp(r'[ýÿ]'), 'y')
        .replaceAll(RegExp(r'[ç]'), 'c')
        .replaceAll(RegExp(r'[ñ]'), 'n')
        .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// Calculates the relevance score of a [recipe] against a [cleanQuery].
  /// Returns a positive score if the recipe matches, or 0.0 if it does not match.
  static double calculateScore(Recipe recipe, String rawQuery) {
    final query = normalize(rawQuery);
    if (query.isEmpty) return 1.0;

    final tokens = query.split(' ').where((t) => t.isNotEmpty).toList();
    if (tokens.isEmpty) return 1.0;

    final title = normalize(recipe.title);
    final titleWords = title.split(' ').where((w) => w.isNotEmpty).toList();
    final category = normalize(recipe.category);
    final tags = recipe.tags.map(normalize).toList();
    final ingredients = recipe.ingredients.map(normalize).toList();
    final description = normalize(recipe.description);

    // Multi-token AND requirement: Every query token must appear somewhere in the recipe
    for (final token in tokens) {
      final inTitle = title.contains(token);
      final inCategory = category.contains(token);
      final inTags = tags.any((tag) => tag.contains(token));
      final inIngredients = ingredients.any((ing) => ing.contains(token));
      final inDescription = description.contains(token);

      if (!inTitle && !inCategory && !inTags && !inIngredients && !inDescription) {
        return 0.0; // Token missing entirely
      }
    }

    double score = 0.0;

    // ── 1. Full Query Title Matching (Highest Priority Tier) ─────────────────
    if (title == query) {
      score += 10000.0; // Exact title match
    } else if (title.startsWith(query)) {
      score += 6500.0; // Title starts with full query
    } else {
      // Check if any individual word in the title starts with the query
      bool wordPrefixMatched = false;
      for (int i = 0; i < titleWords.length; i++) {
        if (titleWords[i].startsWith(query)) {
          // Earlier words receive higher rank
          score += (4500.0 - (i * 350.0)).clamp(2200.0, 4500.0);
          wordPrefixMatched = true;
          break;
        }
      }

      if (!wordPrefixMatched && title.contains(query)) {
        score += 1400.0; // Substring inside title
      }
    }

    // ── 2. Individual Token Matches in Title ─────────────────────────────────
    for (final token in tokens) {
      if (title.startsWith(token)) {
        score += 700.0;
      } else if (titleWords.any((w) => w.startsWith(token))) {
        score += 450.0;
      } else if (title.contains(token)) {
        score += 200.0;
      }
    }

    // ── 3. Tags and Cuisine Matching ─────────────────────────────────────────
    for (final tag in tags) {
      if (tag == query) {
        score += 1600.0;
      } else if (tag.startsWith(query)) {
        score += 900.0;
      } else if (tag.contains(query)) {
        score += 350.0;
      }
    }

    // ── 4. Category Matching ─────────────────────────────────────────────────
    if (category == query) {
      score += 700.0;
    } else if (category.startsWith(query)) {
      score += 450.0;
    }

    // ── 5. Ingredients Matching ──────────────────────────────────────────────
    for (final ing in ingredients) {
      final ingWords = ing.split(' ').where((w) => w.isNotEmpty);
      if (ingWords.any((w) => w.startsWith(query))) {
        score += 220.0;
      } else if (ing.contains(query)) {
        score += 80.0;
      }
    }

    // ── 6. Description & Notes Matching ──────────────────────────────────────
    if (description.split(' ').any((w) => w.startsWith(query))) {
      score += 60.0;
    } else if (description.contains(query)) {
      score += 25.0;
    }

    // ── 7. Specificity Bonus (Shorter, more focused titles rank higher) ───────
    if (score > 0.0) {
      final specificity = (100.0 - title.length.toDouble().clamp(0.0, 80.0));
      score += specificity;
    }

    return score;
  }

  /// Searches and intelligently sorts [recipes] according to [query],
  /// [category], [maxCookTime], and [sortBy].
  static List<Recipe> search({
    required List<Recipe> recipes,
    required String query,
    String? category,
    int? maxCookTime,
    String? sortBy = 'relevance',
  }) {
    final cleanQuery = query.trim();

    // 1. Filter by category, maxCookTime, and query relevance
    final List<_SearchCandidate> matches = [];

    for (int i = 0; i < recipes.length; i++) {
      final recipe = recipes[i];

      // Category filter
      if (category != null && category.isNotEmpty && category != 'All') {
        if (recipe.category.toLowerCase() != category.toLowerCase()) {
          continue;
        }
      }

      // Max cook time filter
      if (maxCookTime != null && maxCookTime > 0) {
        if (recipe.cookMinutes > maxCookTime) {
          continue;
        }
      }

      // Query score
      final score = cleanQuery.isEmpty ? 1.0 : calculateScore(recipe, cleanQuery);
      if (score > 0.0) {
        matches.add(_SearchCandidate(recipe, score, i));
      }
    }

    // 2. Intelligent Sorting
    final isQueryActive = cleanQuery.isNotEmpty;
    final activeSort = sortBy ?? (isQueryActive ? 'relevance' : 'quickest');

    matches.sort((a, b) {
      final rA = a.recipe;
      final rB = b.recipe;
      final scoreA = a.score;
      final scoreB = b.score;

      // ── Relevance Sort Mode ────────────────────────────────────────────────
      if (activeSort == 'relevance') {
        final scoreCmp = scoreB.compareTo(scoreA); // Higher score first
        if (scoreCmp != 0) return scoreCmp;

        // Tie breaker 1: More specific / shorter title first
        final lenCmp = rA.title.length.compareTo(rB.title.length);
        if (lenCmp != 0) return lenCmp;

        // Tie breaker 2: Faster total time
        final timeCmp = rA.totalMinutes.compareTo(rB.totalMinutes);
        if (timeCmp != 0) return timeCmp;

        // Tie breaker 3: Alphabetical
        final titleCmp = rA.title.compareTo(rB.title);
        if (titleCmp != 0) return titleCmp;

        return a.index.compareTo(b.index);
      }

      // ── Explicit Sort Modes with Query Relevance Protection ────────────────
      // When a query is active, massive relevance tier differences (> 800 pts)
      // must still prioritize direct title/cuisine matches over incidental matches.
      if (isQueryActive && (scoreA - scoreB).abs() > 800.0) {
        return scoreB.compareTo(scoreA);
      }

      if (activeSort == 'quickest') {
        final cmp = rA.totalMinutes.compareTo(rB.totalMinutes);
        if (cmp != 0) return cmp;
        return a.index.compareTo(b.index);
      } else if (activeSort == 'prep') {
        final cmp = rA.prepMinutes.compareTo(rB.prepMinutes);
        if (cmp != 0) return cmp;
        return a.index.compareTo(b.index);
      } else if (activeSort == 'title') {
        final cmp = rA.title.compareTo(rB.title);
        if (cmp != 0) return cmp;
        return a.index.compareTo(b.index);
      }

      // Default tie breaker
      final scoreCmp = scoreB.compareTo(scoreA);
      if (scoreCmp != 0) return scoreCmp;

      final lenCmp = rA.title.length.compareTo(rB.title.length);
      if (lenCmp != 0) return lenCmp;

      final titleCmp = rA.title.compareTo(rB.title);
      if (titleCmp != 0) return titleCmp;

      return a.index.compareTo(b.index);
    });

    return matches.map((m) => m.recipe).toList();
  }
}

class _SearchCandidate {
  final Recipe recipe;
  final double score;
  final int index;

  const _SearchCandidate(this.recipe, this.score, this.index);
}
