# 🍳 cook_mate_core

[![Pub Version](https://img.shields.io/pub/v/cook_mate_core?style=flat-square&color=blue)](https://pub.dev/packages/cook_mate_core)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=flat-square)](https://opensource.org/licenses/MIT)
[![CI](https://img.shields.io/github/actions/workflow/status/AbdullahAzeem12/CookMate/ci.yml?branch=main&style=flat-square)](https://github.com/AbdullahAzeem12/CookMate/actions)

A lightweight, pure Dart headless culinary engine for building recipe apps, kitchen tools, meal planners, and food service software.

Zero Flutter SDK or runtime dependencies — runs on command-line utilities, backend servers (Dart Frog / Shelf), web applications, and Flutter mobile/desktop apps.

---

## ✨ Features

- ⚖️ **Dynamic Serving Scaler**: Real-world culinary scaling curves:
  - Smart fraction parsing (`1/2 cup` -> `1 1/2 cups` when tripled).
  - Attached unit scaling (`250g`, `400ml`, `1.5L`).
  - Sub-linear prep times (economies of scale in the kitchen).
  - Thermal mass cook time curves.
- 🔄 **Culinary Unit Converter**: Bidirectional conversion between Metric and US Imperial units for mass (`g`, `kg`, `oz`, `lb`), volume (`ml`, `l`, `tsp`, `tbsp`, `cup`), and oven temperatures (`°C` to `°F`).
- 🔍 **Diacritic-Agnostic Search**: Real-time multi-token relevance ranker that handles prefixes, typos, and accents (`creme brulee` matches `crème brûlée`).
- 🧑‍🍳 **Chef AI Recipe Autofill**: Built-in culinary heuristics dictionary that generates realistic gourmet ingredients, instructions, and times from simple dish titles.
- 📦 **Standard Recipe Schema**: Fully typed, immutable `Recipe` data model with resilient JSON serialization.

---

## 🚀 Installation

Add `cook_mate_core` to your `pubspec.yaml`:

```yaml
dependencies:
  cook_mate_core: ^1.0.0
```

Or via terminal:

```bash
dart pub add cook_mate_core
```

---

## 📖 Quick Start

```dart
import 'package:cook_mate_core/cook_mate_core.dart';

void main() {
  // 1. Create a recipe
  const recipe = Recipe(
    id: 'pasta-carbonara',
    title: 'Classic Spaghetti Carbonara',
    description: 'Authentic Roman pasta with guanciale, pecorino, and egg yolks.',
    category: 'Quick & Easy',
    imageUrl: 'https://images.unsplash.com/...',
    ingredients: [
      '350g Spaghetti',
      '150g Guanciale or pancetta',
      '4 Large egg yolks',
      '50g Pecorino Romano cheese',
      '1 tsp Freshly cracked black pepper',
    ],
    instructions: [
      'Bring a large pot of salted water to boil and cook pasta until al dente.',
      'Crisp guanciale in a skillet over medium heat.',
      'Whisk egg yolks and pecorino in a bowl.',
      'Toss hot pasta with guanciale, remove from heat, and mix in egg mixture.',
    ],
    prepMinutes: 10,
    cookMinutes: 15,
    servings: 4,
    difficulty: 'Medium',
    tags: ['Italian', 'Pasta', 'Dinner'],
  );

  // 2. Scale for 8 guests (Double servings)
  final scaled = RecipeScaler.scale(recipe: recipe, targetServings: 8);
  print('Servings: ${scaled.servings}');
  print('Prep: ${scaled.prepMinutes}m | Cook: ${scaled.cookMinutes}m');
  for (final ing in scaled.ingredients) {
    print('- ${ing.scaled}');
  }

  // 3. Convert units (Metric <-> Imperial)
  final oz = UnitConverter.gramsToOunces(350);
  print('350g in ounces: ${oz.toStringAsFixed(1)} oz');

  // 4. Diacritic-agnostic search
  final matchScore = RecipeSearchEngine.calculateScore(
    recipe,
    'spaghetti carbonara',
  );
  print('Search relevance score: $matchScore');
}
```

---

## 📄 License

MIT © [Abdullah Azeem](https://github.com/AbdullahAzeem12)
