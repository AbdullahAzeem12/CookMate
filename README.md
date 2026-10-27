# 🍲 CookMate — Your Personal Kitchen Companion

[![Flutter Version](https://img.shields.io/badge/Flutter-3.47.2-02569B?logo=flutter)](https://flutter.dev)
[![Dart Version](https://img.shields.io/badge/Dart-3.13.2-0175C2?logo=dart)](https://dart.dev)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Build Status](https://img.shields.io/badge/Tests-13%20Passed-success)](test/)

> **Phase 1 Demo Assignment**: Flutter Foundations, UI Mastery, Navigation & Flutter Architecture.  
> An offline-first, cross-platform culinary discovery and cooking companion app built with **Material Design 3**, **Liquid Glassmorphism**, **GoRouter deep linking**, **Stateful Shell navigation**, **Riverpod state management**, and **Firebase Firestore submission readiness**.

---

## 📱 Visual Showcase & Aesthetic Direction

CookMate is styled as a luxury editorial digital cookbook inspired by modern food publications and high-end culinary apps:
* **Liquid Glassmorphism**: Frosted glass surfaces with clipped `BackdropFilter` gaussian blur, fine specular borders, subtle ambient shadows, and luminous buttons.
* **Warm Gourmet Color Palette**:
  * 🌲 **Forest Green** (`#173D31`) — Primary Brand
  * 🌾 **Warm Cream** (`#F8F4EA`) — Organic Editorial Surface
  * 🍋 **Citrus Lime** (`#D8F078`) — High-energy Accent
  * 🍉 **Soft Coral** (`#F18C72`) — Interactive Highlights & Heart Actions
  * 🌿 **Secondary Sage** (`#A8C4AD`) — Subtle Indicators
  * 🌑 **Deep Surface** (`#12251F`) — Dark Mode Background
* **Seamless Dark Mode**: Full Material Design 3 light & dark theme switching with a single tap.
* **Shared-Element Hero Transitions**: Fluid image enlargement and morphing from cards to detail screens (`recipe-image-{id}`).

---

## 🌟 Core Features & The 6 Primary Screens

| Screen | Route | Description & Key Interactions |
|---|---|---|
| **Home** | `/` | Personalized welcome header, search bar shortcut, category filters with live badges, Chef's Pick hero banner with glass overlay, horizontal trending carousel, and editor's grid. |
| **Explore / List** | `/` | Responsive multi-column grid, category filtering (`All`, `Quick & Easy`, `Healthy Meals`, `Desserts`), and sorting (Shortest Cook Time, Prep Time, Alphabetical A-Z). |
| **Recipe Detail** | `/recipes/:recipeId` | Shared Hero photograph, description, prep/cook/total metrics, serving adjuster (`-` / `+`), **interactive checkable ingredients list**, numbered instructions, and clipboard recipe sharing. |
| **Interactive Cooking Mode** | Modal / Sheet | Accessible from Recipe Detail via *"Enter Cooking Mode"*. Step-by-step cooking guide with step progress bar, pro chef tips, and a **real-time countdown kitchen timer** with Start, Pause, and Reset controls! |
| **Search** | `/search?q=query` | Real-time search across titles, ingredients, descriptions, and tags. Supports **direct deep link with preserved query parameter** (`/search?q=pasta`), cook-time filters (`≤ 10 min`, `≤ 20 min`, `≤ 35 min`), and empty-state term suggestions. |
| **Favorites** | `/favorites` | Reactive saved recipes collection backed by `shared_preferences`. Persists across device restarts. Features instantaneous optimistic heart toggle and clear-all with confirmation dialog. |
| **Submit Recipe** | `/submit` | Validated recipe creation form with `GlobalKey<FormState>`, dynamic ingredient rows (`+ Add Row`), dynamic instruction steps (`+ Add Step`), time and serving numeric constraints, anti-double-submission guard, and hybrid cloud/local draft persistence. |

---

## 🏗️ Technical Architecture

CookMate follows a clean, feature-first layered architecture:

```
lib/
├── main.dart                               # App entry point (Firebase optional init + ProviderScope)
├── app/
│   ├── app.dart                            # MaterialApp.router configuration & theme wiring
│   └── router.dart                         # GoRouter with StatefulShellRoute & deep links
├── core/
│   ├── constants/                          # App constants (categories, breakpoints, keys)
│   └── theme/                              # Brand colors, typography, Material 3 ThemeData
├── shared/
│   └── widgets/                            # GlassSurface, RecipeCard, GlassSearchBar, FavoriteButton,
│                                           # RecipeMetadataRow, CookingTimerSheet, EmptyState, Shimmer
└── features/
    ├── home/                               # Home discovery screen
    ├── recipes/
    │   ├── data/                           # LocalJsonRecipeDataSource & DefaultRecipeRepository
    │   ├── domain/models/recipe.dart       # Typed Recipe model with derived totalMinutes
    │   └── presentation/                   # ExploreScreen, RecipeDetailScreen, Riverpod providers
    ├── search/                             # SearchScreen with query param synchronization
    ├── favorites/                          # LocalFavoritesRepository (SharedPreferences) & FavoritesScreen
    └── submission/                         # HybridRecipeSubmissionRepository & SubmitRecipeScreen
```

### State Management: Riverpod
* `recipeRepositoryProvider`: Singleton repository coordinating local seed data and user submissions.
* `allRecipesProvider`: Asynchronous feed providing deduplicated recipes.
* `favoritesNotifierProvider`: AsyncNotifier managing the `Set<String>` of saved recipe IDs with optimistic UI updates.
* `favoriteRecipesProvider`: Reactive selector resolving favorite IDs against the recipe catalogue.
* `searchFilterProvider` & `searchResultsProvider`: Live parameter filtering and multi-field keyword matching.
* `themeModeProvider`: StateProvider toggling between Light and Dark themes.

---

## 📦 Bundled 15-Recipe JSON Dataset

Located at [`assets/data/recipes.json`](assets/data/recipes.json) and parsed through typed `Recipe.fromJson()`:

* **Quick & Easy**:
  1. `classic-pasta` — Creamy Tomato Basil Pasta
  2. `vegetable-stir-fry` — Crispy Sesame Vegetable Stir-Fry
  3. `chicken-wrap` — Mediterranean Herb Chicken Wrap
  4. `garlic-fried-rice` — Golden Garlic Scallion Fried Rice
  5. `tomato-omelette` — Rustic Garden Tomato & Herb Omelette
* **Healthy Meals**:
  6. `grilled-chicken-bowl` — Green Goddess Grilled Chicken Bowl
  7. `quinoa-salad` — Zesty Mediterranean Quinoa Crunch Salad
  8. `baked-salmon` — Garlic Herb Butter Sheet Pan Salmon
  9. `lentil-soup` — Golden Turmeric French Lentil Soup
  10. `avocado-toast` — Artisanal Sourdough Avocado Tartine
* **Desserts**:
  11. `chocolate-brownies` — Fudgy Double Dark Chocolate Brownies
  12. `strawberry-cheesecake` — Velvety Strawberry Swirl Cheesecake
  13. `banana-pancakes` — Fluffy Soufflé Banana Oatmeal Pancakes
  14. `mango-pudding` — Silky Tropical Alphonso Mango Pudding
  15. `apple-crumble` — Warm Cinnamon Honeycrisp Apple Crumble

---

## 🚀 Setup & Running Instructions

### Prerequisites
* **Flutter SDK**: `^3.47.2` (Channel stable)
* **Dart SDK**: `^3.13.2`
* Supported targets: **Android**, **iOS**, **Web (Chrome / Edge)**, **Windows Desktop**

### Installation
```bash
# 1. Clone repository
git clone <your-github-repo-url>
cd CookMate

# 2. Fetch dependencies
flutter pub get

# 3. Verify code formatting and static analysis
dart format .
flutter analyze

# 4. Run automated test suite (13 unit and widget tests)
flutter test

# 5. Launch application on Chrome or connected device
flutter run -d chrome
# or on Windows desktop:
flutter run -d windows
```

---

## ☁️ Firebase Backend & Security Rules

CookMate is **offline-first**: it boots up and operates with the complete 15-recipe dataset without requiring active cloud credentials. When Firebase is configured, community submissions are saved to Cloud Firestore under `recipe_submissions`.

### Firestore Security Rules (`firestore.rules`)
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /recipes/{recipeId} {
      allow read: if true;
      allow write: if false; // Only Admin SDK
    }
    match /recipe_submissions/{submissionId} {
      allow read: if request.auth != null;
      allow create: if request.resource.data.status == 'pending' &&
                       request.resource.data.title.size() >= 3 &&
                       request.resource.data.prepMinutes >= 1 &&
                       request.resource.data.servings >= 1;
      allow update, delete: if request.auth != null && request.auth.uid == resource.data.authorUid;
    }
  }
}
```

### Optional Firebase Setup Steps
1. Install FlutterFire CLI: `dart pub global activate flutterfire_cli`
2. Run `flutterfire configure` and select your Firebase project.
3. Deploy security rules: `firebase deploy --only firestore:rules`

---

## 🧪 Automated Testing Suite

The project includes unit and widget tests covering all critical paths:

```bash
flutter test
```

### Test Coverage Highlights:
- ✅ **Recipe Model**: Complete JSON parsing, missing/null field fallback resilience, and derived `totalMinutes` verification.
- ✅ **Recipe Repository**: Category filtering, multi-field keyword search (titles, ingredients, tags), maximum cooking time thresholds, sorting, and submission deduplication.
- ✅ **Favorites Repository**: Persistence in `shared_preferences`, duplicate prevention, removal, and collection purging.
- ✅ **Widget Tests**: Application boot, responsive navigation shell, category shortcut rendering, branch tab navigation across Explore, Search, and Saved.

---

## 📹 Screen Recording Demo Script (2–3 Minutes)

1. **Introduction & Home Screen (0:00–0:35)**:
   - Introduce CookMate and highlight the liquid-glass design tokens and Material Design 3 theme.
   - Showcase the personalized welcome header, search pill, category shortcuts, Chef's Pick hero card, and the horizontal trending carousel.
   - Tap the theme mode switcher in the top bar to demonstrate the light/dark mode transition.
2. **Explore & Filtering (0:35–1:00)**:
   - Navigate to the **Explore** tab. Filter by "Quick & Easy", "Healthy Meals", and "Desserts".
   - Demonstrate the sort menu (Shortest Cook Time, Prep Time, Alphabetical).
3. **Recipe Detail & Hero Animation (1:00–1:35)**:
   - Tap "Creamy Tomato Basil Pasta" to show the smooth **Hero image transition**.
   - Adjust servings using `-` / `+` stepper.
   - Tap ingredient checkboxes to check off items while preparing.
   - Tap **"Enter Cooking Mode"** to launch the step-by-step sheet with the **live countdown timer**!
4. **Search with Deep Linking (1:35–1:55)**:
   - Navigate to **Search**, enter "quinoa" or "chocolate", and observe real-time search results.
   - Demonstrate cooking time pill filters (`≤ 15 min`).
5. **Favorites & Persistence (1:55–2:15)**:
   - Heart 2 recipes. Navigate to the **Saved** tab to see them displayed.
   - Reload/restart the app to demonstrate that favorites persist via `shared_preferences`.
6. **Recipe Submission (2:15–2:45)**:
   - Tap the `+` Submit Recipe action.
   - Attempt submission with empty fields to show validation errors.
   - Fill in a community recipe with dynamic ingredient/step rows, submit, and see it immediately appear in the cookbook!
7. **Responsive Layout & Wrap-Up (2:45–3:00)**:
   - Resize browser / window to show tablet & desktop Navigation Rail adaptation.

---

## 📄 License
This project is licensed under the MIT License.
