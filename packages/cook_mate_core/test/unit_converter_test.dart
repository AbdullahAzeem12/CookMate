import 'package:cook_mate_core/cook_mate_core.dart';
import 'package:test/test.dart';

void main() {
  group('UnitConverter Tests', () {
    test('Mass conversions: grams <-> ounces <-> pounds', () {
      final oz = UnitConverter.gramsToOunces(100);
      expect(oz, closeTo(3.527, 0.01));

      final g = UnitConverter.ouncesToGrams(oz);
      expect(g, closeTo(100.0, 0.01));

      final lb = UnitConverter.kilogramsToPounds(1.0);
      expect(lb, closeTo(2.204, 0.01));

      final kg = UnitConverter.poundsToKilograms(lb);
      expect(kg, closeTo(1.0, 0.01));
    });

    test('Volume conversions: ml <-> fluid ounces <-> cups <-> tbsp <-> tsp', () {
      final cups = UnitConverter.mlToCups(236.588);
      expect(cups, closeTo(1.0, 0.01));

      final ml = UnitConverter.cupsToMl(2.0);
      expect(ml, closeTo(473.17, 0.1));

      expect(UnitConverter.tablespoonsToTeaspoons(1.0), 3.0);
      expect(UnitConverter.teaspoonsToTablespoons(3.0), 1.0);
      expect(UnitConverter.cupsToTablespoons(1.0), 16.0);
      expect(UnitConverter.tablespoonsToCups(16.0), 1.0);
    });

    test('Temperature conversions: Celsius <-> Fahrenheit', () {
      expect(UnitConverter.celsiusToFahrenheit(0), 32.0);
      expect(UnitConverter.celsiusToFahrenheit(100), 212.0);
      expect(UnitConverter.celsiusToFahrenheit(180), 356.0);

      expect(UnitConverter.fahrenheitToCelsius(32), 0.0);
      expect(UnitConverter.fahrenheitToCelsius(212), 100.0);
      expect(UnitConverter.fahrenheitToCelsius(350), closeTo(176.67, 0.01));

      expect(UnitConverter.roundOvenTemperature(356), 355);
    });

    test('convertIngredientSystem switches between metric and imperial text', () {
      // Metric to Imperial
      final imperial1 = UnitConverter.convertIngredientSystem(
        '250g Rigatoni pasta',
        MeasurementSystem.imperial,
      );
      expect(imperial1, contains('oz'));

      final imperial2 = UnitConverter.convertIngredientSystem(
        '500ml Chicken broth',
        MeasurementSystem.imperial,
      );
      expect(imperial2, contains('cups'));

      // Imperial to Metric
      final metric1 = UnitConverter.convertIngredientSystem(
        '2 cups Whole milk',
        MeasurementSystem.metric,
      );
      expect(metric1, contains('ml'));

      final metric2 = UnitConverter.convertIngredientSystem(
        '8 oz Cream cheese',
        MeasurementSystem.metric,
      );
      expect(metric2, contains('g'));
    });
  });
}
