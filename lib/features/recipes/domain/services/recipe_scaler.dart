import 'dart:math' as math;

import '../models/recipe.dart';

/// Represents an ingredient that has been intelligently scaled for a target number of servings.
class ScaledIngredient {
  final String original;
  final String scaled;
  final bool hasChanged;

  const ScaledIngredient({
    required this.original,
    required this.scaled,
    required this.hasChanged,
  });
}

/// Holds all dynamically scaled attributes of a recipe for a specific serving count.
class ScaledRecipeInfo {
  final int servings;
  final int prepMinutes;
  final int cookMinutes;
  final int totalMinutes;
  final double ratio;
  final List<ScaledIngredient> ingredients;

  const ScaledRecipeInfo({
    required this.servings,
    required this.prepMinutes,
    required this.cookMinutes,
    required this.totalMinutes,
    required this.ratio,
    required this.ingredients,
  });
}

/// Intelligent culinary scaling service that dynamically recalculates:
/// 1. Ingredient quantities (with smart fractions, unit pluralization, and parenthetical preservation).
/// 2. Prep times (logarithmic / diminishing return scaling for realistic culinary efficiency).
/// 3. Cook times (thermal / batch culinary curve).
class RecipeScaler {
  const RecipeScaler._();

  /// Scales a recipe's ingredients and times for [targetServings].
  static ScaledRecipeInfo scale({
    required Recipe recipe,
    required int targetServings,
  }) {
    final baseServings = recipe.servings > 0 ? recipe.servings : 1;
    final clampedTarget = targetServings.clamp(1, 48);
    final ratio = clampedTarget / baseServings;

    final prep = scalePrepMinutes(basePrep: recipe.prepMinutes, ratio: ratio);
    final cook = scaleCookMinutes(baseCook: recipe.cookMinutes, ratio: ratio);

    final scaledIngredients = recipe.ingredients.map((raw) {
      if (ratio == 1.0) {
        return ScaledIngredient(original: raw, scaled: raw, hasChanged: false);
      }
      final scaledText = scaleIngredientText(ingredient: raw, factor: ratio);
      return ScaledIngredient(
        original: raw,
        scaled: scaledText,
        hasChanged: scaledText != raw,
      );
    }).toList();

    return ScaledRecipeInfo(
      servings: clampedTarget,
      prepMinutes: prep,
      cookMinutes: cook,
      totalMinutes: prep + cook,
      ratio: ratio,
      ingredients: scaledIngredients,
    );
  }

  /// Culinary prep time scaling with realistic economies of scale:
  /// Prepping 4 onions takes longer than 2, but setup/cleanup time is constant.
  static int scalePrepMinutes({required int basePrep, required double ratio}) {
    if (basePrep <= 0) return 0;
    if (ratio == 1.0) return basePrep;

    // Sub-linear curve: prep increases by ~35% per 100% serving increase
    final factor = 1.0 + (ratio - 1.0) * 0.35;
    final scaled = (basePrep * factor).round();
    return math.max(1, scaled);
  }

  /// Culinary cook time scaling based on thermal mass and batch physics:
  /// Boiling soup or roasting extra portions takes slightly more time, but not 2x.
  static int scaleCookMinutes({required int baseCook, required double ratio}) {
    if (baseCook <= 0) return 0;
    if (ratio == 1.0) return baseCook;

    // Thermal mass curve: cook increases by ~20% per 100% serving increase
    final factor = 1.0 + (ratio - 1.0) * 0.20;
    final scaled = (baseCook * factor).round();
    return math.max(1, scaled);
  }

  /// Intelligently parses and scales an ingredient string.
  static String scaleIngredientText({
    required String ingredient,
    required double factor,
  }) {
    if (factor == 1.0 || ingredient.trim().isEmpty) {
      return ingredient;
    }

    final trimmed = ingredient.trim();

    // ── 1. Pattern: "2 × 200g A5 Wagyu" or "2 x 180g cod" ─────────────────
    final multiItemRegex = RegExp(
      r'^(\d+)\s*([×x])\s*(\d+(?:\.\d+)?)\s*([a-zA-Z]+)?(.*)$',
    );
    final multiMatch = multiItemRegex.firstMatch(trimmed);
    if (multiMatch != null) {
      final baseCount = int.tryParse(multiMatch.group(1) ?? '1') ?? 1;
      final scaledCount = (baseCount * factor);
      final sep = multiMatch.group(2);
      final weight = multiMatch.group(3);
      final unit = multiMatch.group(4) ?? '';
      final rest = multiMatch.group(5) ?? '';
      final countStr = formatQuantity(scaledCount);
      return '$countStr $sep $weight$unit$rest';
    }

    // ── 2. Pattern: Attached units (e.g. "250g Rigatoni", "400ml stock", "1.5L") ──
    final attachedUnitRegex = RegExp(
      r'^(\d+(?:\.\d+)?)\s*(g|kg|ml|l|L|oz|lb)\b(.*)$',
    );
    final attachedMatch = attachedUnitRegex.firstMatch(trimmed);
    if (attachedMatch != null) {
      final baseVal = double.tryParse(attachedMatch.group(1) ?? '') ?? 0.0;
      final unit = attachedMatch.group(2) ?? '';
      final rest = attachedMatch.group(3) ?? '';
      final scaledVal = baseVal * factor;

      final valStr = (unit.toLowerCase() == 'g' || unit.toLowerCase() == 'ml')
          ? scaledVal.round().toString()
          : formatQuantity(scaledVal);

      return '$valStr$unit$rest';
    }

    // ── 3. Pattern: Fraction at start (e.g. "1/2 cup Heavy cream", "1 1/2 tsp salt") ──
    final fractionRegex = RegExp(r'^(?:(\d+)\s+)?(\d+)\/(\d+)\s+(.*)$');
    final fracMatch = fractionRegex.firstMatch(trimmed);
    if (fracMatch != null) {
      final whole = fracMatch.group(1) != null
          ? double.tryParse(fracMatch.group(1)!) ?? 0.0
          : 0.0;
      final num = double.tryParse(fracMatch.group(2) ?? '') ?? 1.0;
      final denom = double.tryParse(fracMatch.group(3) ?? '') ?? 2.0;
      final baseVal = whole + (num / denom);
      final scaledVal = baseVal * factor;
      final rest = fracMatch.group(4) ?? '';

      final formattedQty = formatQuantity(scaledVal);
      final adjustedRest = _adjustUnitPluralization(rest, scaledVal);
      return '$formattedQty $adjustedRest';
    }

    // ── 4. Pattern: Standard "Number + Adjective(s) + Noun/Unit" (e.g. "2 Fresh salmon fillets", "1 can (400g)") ──
    final standardRegex = RegExp(r'^(\d+(?:\.\d+)?)\s+(.+)$');
    final stdMatch = standardRegex.firstMatch(trimmed);
    if (stdMatch != null) {
      final baseVal = double.tryParse(stdMatch.group(1) ?? '') ?? 0.0;
      final fullRest = stdMatch.group(2) ?? '';
      final scaledVal = baseVal * factor;

      final formattedQty = formatQuantity(scaledVal);
      final adjustedPhrase = _adjustNounPluralizationInPhrase(fullRest, scaledVal);

      // Scale parenthetical total weight like "(400g)" unless it has "each"
      final adjustedWithParen = _scaleParentheticalWeight(adjustedPhrase, factor);

      return '$formattedQty $adjustedWithParen';
    }

    // ── 5. Qualitative ingredients (e.g. "Sea salt and black pepper to taste") ──
    return trimmed;
  }

  /// Converts a decimal number into beautiful culinary fraction notation.
  /// (e.g. 0.5 -> "1/2", 1.5 -> "1 1/2", 2.25 -> "2 1/4", 250.0 -> "250")
  static String formatQuantity(double value) {
    if (value <= 0) return '0';

    // Check if within roundoff of a whole integer
    final nearestInt = value.round();
    if ((value - nearestInt).abs() < 0.04) {
      return nearestInt.toString();
    }

    // For large quantities (e.g. >= 15), round to clean integer
    if (value >= 15.0) {
      return value.round().toString();
    }

    final whole = value.floor();
    final remainder = value - whole;

    // Common culinary fraction lookup
    const fractions = [
      (0.125, '1/8'),
      (0.25, '1/4'),
      (0.333, '1/3'),
      (0.5, '1/2'),
      (0.667, '2/3'),
      (0.75, '3/4'),
    ];

    double minDiff = 0.055;
    String? bestFraction;

    for (final f in fractions) {
      final diff = (remainder - f.$1).abs();
      if (diff < minDiff) {
        minDiff = diff;
        bestFraction = f.$2;
      }
    }

    if (bestFraction != null) {
      if (whole == 0) return bestFraction;
      return '$whole $bestFraction';
    }

    // Clean decimal fallback without trailing zeroes
    final fixed = value.toStringAsFixed(1);
    if (fixed.endsWith('.0')) {
      return fixed.substring(0, fixed.length - 2);
    }
    return fixed;
  }

  /// Adjusts pluralization of common kitchen measurement units and nouns.
  static String _adjustSingleUnit(String word, double qty) {
    // Strip trailing punctuation like commas for matching
    String cleanWord = word;
    String trailingPunct = '';
    if (word.endsWith(',') || word.endsWith('.')) {
      cleanWord = word.substring(0, word.length - 1);
      trailingPunct = word.substring(word.length - 1);
    }

    final lower = cleanWord.toLowerCase();
    final isPlural = qty > 1.05;

    // Units that pluralize with 's' or 'es'
    const plurals = {
      'clove': 'cloves',
      'can': 'cans',
      'head': 'heads',
      'bunch': 'bunches',
      'fillet': 'fillets',
      'stalk': 'stalks',
      'slice': 'slices',
      'piece': 'pieces',
      'pinch': 'pinches',
      'egg': 'eggs',
      'sprig': 'sprigs',
      'sheet': 'sheets',
      'cup': 'cups',
      'lemon': 'lemons',
      'lime': 'limes',
      'carrot': 'carrots',
      'onion': 'onions',
      'potato': 'potatoes',
      'tomato': 'tomatoes',
      'avocado': 'avocados',
      'pepper': 'peppers',
      'tortilla': 'tortillas',
      'breast': 'breasts',
      'thigh': 'thighs',
      'wrap': 'wraps',
      'pancake': 'pancakes',
      'ramen': 'ramen',
    };

    // If unit is singular and qty > 1, make plural
    for (final entry in plurals.entries) {
      if (lower == entry.key && isPlural) {
        return _matchCase(cleanWord, entry.value) + trailingPunct;
      }
      if (lower == entry.value && !isPlural) {
        return _matchCase(cleanWord, entry.key) + trailingPunct;
      }
    }

    return word;
  }

  /// Scans through the first few words of an ingredient phrase (skipping adjectives like "fresh", "large")
  /// to pluralize or singularize the key countable unit or noun.
  static String _adjustNounPluralizationInPhrase(String phrase, double qty) {
    final words = phrase.split(' ');
    if (words.isEmpty) return phrase;

    // Look at the first 4 words to find the countable noun/unit
    for (int i = 0; i < math.min(words.length, 4); i++) {
      final current = words[i];
      // Don't modify words inside parentheses
      if (current.startsWith('(')) break;

      final adjusted = _adjustSingleUnit(current, qty);
      if (adjusted != current) {
        words[i] = adjusted;
        return words.join(' ');
      }
    }

    return phrase;
  }

  static String _adjustUnitPluralization(String rest, double qty) {
    return _adjustNounPluralizationInPhrase(rest, qty);
  }

  /// Scales parenthetical measurements like "(400g)" -> "(800g)"
  /// Preserves per-item annotations like "(180g each, skin-on)".
  static String _scaleParentheticalWeight(String text, double factor) {
    final parenRegex = RegExp(r'\(([^)]+)\)');
    return text.replaceAllMapped(parenRegex, (match) {
      final inner = match.group(1) ?? '';
      // If it says "each", keep as-is (e.g. 180g each)
      if (inner.toLowerCase().contains('each')) {
        return match.group(0)!;
      }

      final weightRegex = RegExp(r'^(\d+(?:\.\d+)?)\s*(g|ml|oz)\b(.*)$', caseSensitive: false);
      final wMatch = weightRegex.firstMatch(inner);
      if (wMatch != null) {
        final val = double.tryParse(wMatch.group(1) ?? '') ?? 0.0;
        final unit = wMatch.group(2) ?? '';
        final rest = wMatch.group(3) ?? '';
        final scaled = val * factor;
        final scaledStr = (unit.toLowerCase() == 'g' || unit.toLowerCase() == 'ml')
            ? scaled.round().toString()
            : formatQuantity(scaled);
        return '($scaledStr$unit$rest)';
      }

      return match.group(0)!;
    });
  }

  static String _matchCase(String template, String target) {
    if (template.isEmpty) return target;
    if (template[0] == template[0].toUpperCase()) {
      return target[0].toUpperCase() + target.substring(1);
    }
    return target.toLowerCase();
  }
}
