/// Target measurement system for conversions.
enum MeasurementSystem {
  /// Metric units (grams, milliliters, kilograms, liters, Celsius).
  metric,

  /// US Customary / Imperial units (ounces, pounds, cups, tablespoons, Fahrenheit).
  imperial,
}

/// Unit conversion utilities for culinary recipes.
/// Handles high-precision conversion of mass, volume, and temperature.
class UnitConverter {
  const UnitConverter._();

  // ─── Mass Conversions (Base unit: Grams) ───────────────────────────────────

  /// Converts grams to ounces (oz).
  static double gramsToOunces(double grams) => grams / 28.349523125;

  /// Converts ounces (oz) to grams.
  static double ouncesToGrams(double ounces) => ounces * 28.349523125;

  /// Converts kilograms (kg) to pounds (lb).
  static double kilogramsToPounds(double kg) => kg * 2.2046226218;

  /// Converts pounds (lb) to kilograms (kg).
  static double poundsToKilograms(double lb) => lb / 2.2046226218;

  /// Converts grams to pounds (lb).
  static double gramsToPounds(double grams) => grams / 453.59237;

  /// Converts pounds (lb) to grams.
  static double poundsToGrams(double lb) => lb * 453.59237;

  // ─── Volume Conversions (Base unit: Milliliters) ───────────────────────────

  /// Converts milliliters to US fluid ounces (fl oz).
  static double mlToFluidOunces(double ml) => ml / 29.5735295625;

  /// Converts US fluid ounces (fl oz) to milliliters.
  static double fluidOuncesToMl(double flOz) => flOz * 29.5735295625;

  /// Converts milliliters to US cups (~236.59 ml, standard culinary 240 ml rounded).
  static double mlToCups(double ml) => ml / 236.5882365;

  /// Converts US cups to milliliters.
  static double cupsToMl(double cups) => cups * 236.5882365;

  /// Converts milliliters to US tablespoons (tbsp = 14.7868 ml).
  static double mlToTablespoons(double ml) => ml / 14.78676478125;

  /// Converts US tablespoons to milliliters.
  static double tablespoonsToMl(double tbsp) => tbsp * 14.78676478125;

  /// Converts milliliters to US teaspoons (tsp = 4.92892 ml).
  static double mlToTeaspoons(double ml) => ml / 4.92892159375;

  /// Converts US teaspoons to milliliters.
  static double teaspoonsToMl(double tsp) => tsp * 4.92892159375;

  /// Converts teaspoons to tablespoons (1 tbsp = 3 tsp).
  static double teaspoonsToTablespoons(double tsp) => tsp / 3.0;

  /// Converts tablespoons to teaspoons.
  static double tablespoonsToTeaspoons(double tbsp) => tbsp * 3.0;

  /// Converts tablespoons to cups (1 cup = 16 tbsp).
  static double tablespoonsToCups(double tbsp) => tbsp / 16.0;

  /// Converts cups to tablespoons.
  static double cupsToTablespoons(double cups) => cups * 16.0;

  // ─── Temperature Conversions ──────────────────────────────────────────────

  /// Converts Celsius (°C) to Fahrenheit (°F).
  static double celsiusToFahrenheit(double c) => (c * 9.0 / 5.0) + 32.0;

  /// Converts Fahrenheit (°F) to Celsius (°C).
  static double fahrenheitToCelsius(double f) => (f - 32.0) * 5.0 / 9.0;

  /// Formats temperature with oven-practical rounding (typically nearest 5 degrees).
  static int roundOvenTemperature(double temp) => ((temp + 2.5) / 5.0).floor() * 5;

  // ─── High-Level Recipe Text Converter ──────────────────────────────────────

  /// Converts recognized measurement units inside an ingredient string
  /// to the [target] system (Metric or Imperial).
  static String convertIngredientSystem(
    String ingredientText,
    MeasurementSystem target,
  ) {
    if (ingredientText.trim().isEmpty) return ingredientText;

    if (target == MeasurementSystem.metric) {
      return _convertToMetric(ingredientText);
    } else {
      return _convertToImperial(ingredientText);
    }
  }

  static String _convertToMetric(String text) {
    // 1. Cups to ml
    final cupsRegex = RegExp(r'^(\d+(?:\.\d+)?)\s*cups?\b(.*)$', caseSensitive: false);
    final cupsMatch = cupsRegex.firstMatch(text.trim());
    if (cupsMatch != null) {
      final cups = double.tryParse(cupsMatch.group(1) ?? '') ?? 0.0;
      final rest = cupsMatch.group(2) ?? '';
      final ml = (cupsToMl(cups)).round();
      return '$ml ml$rest';
    }

    // 2. Ounces (oz) to grams
    final ozRegex = RegExp(r'^(\d+(?:\.\d+)?)\s*oz\b(.*)$', caseSensitive: false);
    final ozMatch = ozRegex.firstMatch(text.trim());
    if (ozMatch != null) {
      final oz = double.tryParse(ozMatch.group(1) ?? '') ?? 0.0;
      final rest = ozMatch.group(2) ?? '';
      final g = (ouncesToGrams(oz)).round();
      return '$g g$rest';
    }

    // 3. Pounds (lb) to kg / grams
    final lbRegex = RegExp(r'^(\d+(?:\.\d+)?)\s*lbs?\b(.*)$', caseSensitive: false);
    final lbMatch = lbRegex.firstMatch(text.trim());
    if (lbMatch != null) {
      final lb = double.tryParse(lbMatch.group(1) ?? '') ?? 0.0;
      final rest = lbMatch.group(2) ?? '';
      final g = (poundsToGrams(lb)).round();
      if (g >= 1000) {
        final kg = (g / 1000.0).toStringAsFixed(1);
        return '$kg kg$rest';
      }
      return '$g g$rest';
    }

    return text;
  }

  static String _convertToImperial(String text) {
    // 1. Grams (g) to oz
    final gRegex = RegExp(r'^(\d+(?:\.\d+)?)\s*g\b(.*)$', caseSensitive: false);
    final gMatch = gRegex.firstMatch(text.trim());
    if (gMatch != null) {
      final g = double.tryParse(gMatch.group(1) ?? '') ?? 0.0;
      final rest = gMatch.group(2) ?? '';
      final oz = gramsToOunces(g);
      final ozStr = oz >= 16.0
          ? '${(oz / 16.0).toStringAsFixed(1)} lb'
          : '${oz.toStringAsFixed(1)} oz';
      return '$ozStr$rest';
    }

    // 2. Milliliters (ml) to cups / fl oz
    final mlRegex = RegExp(r'^(\d+(?:\.\d+)?)\s*ml\b(.*)$', caseSensitive: false);
    final mlMatch = mlRegex.firstMatch(text.trim());
    if (mlMatch != null) {
      final ml = double.tryParse(mlMatch.group(1) ?? '') ?? 0.0;
      final rest = mlMatch.group(2) ?? '';
      if (ml >= 120) {
        final cups = mlToCups(ml);
        return '${cups.toStringAsFixed(1)} cups$rest';
      } else {
        final flOz = mlToFluidOunces(ml);
        return '${flOz.toStringAsFixed(1)} fl oz$rest';
      }
    }

    return text;
  }
}
