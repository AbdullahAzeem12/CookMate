import 'package:cook_mate/features/recipes/domain/models/recipe.dart';
import 'package:cook_mate/shared/widgets/cooking_timer_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const sampleRecipe = Recipe(
    id: 'test-brownies',
    title: 'Fudgy Double Dark Chocolate Brownies Extra Long Title',
    description: 'Decadent chocolate brownies with crisp crackly tops.',
    category: 'Desserts',
    prepMinutes: 12,
    cookMinutes: 22,
    servings: 4,
    difficulty: 'Medium',
    imageUrl: 'assets/images/fudgy_brownies.jpg',
    instructions: [
      'Preheat oven to 350°F and grease pan.',
      'Melt dark chocolate and butter together in a heatproof bowl set over simmering water; cool slightly for 4 minutes.',
      'Whisk eggs and sugar until pale and frothy.',
      'Fold melted chocolate into egg mixture.',
      'Bake for 20-22 minutes until a toothpick comes out with moist crumbs.',
    ],
    ingredients: [
      '200g Dark chocolate',
      '150g Butter',
    ],
    tags: ['dessert', 'baking', 'chocolate'],
    chefNotes: 'Underbaking slightly ensures ultra gooey texture.',
  );

  Widget createTestWidget({Size screenSize = const Size(360, 780)}) {
    return MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(size: screenSize),
        child: const Scaffold(
          body: CookingTimerSheet(recipe: sampleRecipe),
        ),
      ),
    );
  }

  testWidgets('CookingTimerSheet renders without any overflow on compact 360w screen', (tester) async {
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.textContaining('Step 1 of 5'), findsOneWidget);
    expect(find.text('Prep Time'), findsOneWidget);
    expect(find.text('Cook Time'), findsOneWidget);
    expect(find.text('Total Time'), findsOneWidget);
    expect(find.text('Start Cooking Timer'), findsOneWidget);
  });

  testWidgets('CookingTimerSheet renders without overflow on ultra-narrow 320w screen', (tester) async {
    tester.view.physicalSize = const Size(320, 600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(createTestWidget(screenSize: const Size(320, 600)));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Start Cooking Timer'), findsOneWidget);
  });

  testWidgets('Timer toggles between Start and Pause and updates running state', (tester) async {
    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    expect(find.text('Start Cooking Timer'), findsOneWidget);
    expect(find.text('Ready to start timing'), findsOneWidget);

    // Tap Start
    await tester.tap(find.text('Start Cooking Timer'));
    await tester.pump();

    expect(find.text('Pause Timer'), findsOneWidget);
    expect(find.text('Synchronized Cooking In Progress'), findsOneWidget);

    // Fast-forward 2 seconds
    await tester.pump(const Duration(seconds: 2));

    // Tap Pause
    await tester.tap(find.text('Pause Timer'));
    await tester.pump();

    expect(find.text('Start Cooking Timer'), findsOneWidget);
    expect(find.text('Timer paused'), findsOneWidget);
  });

  testWidgets('Fine-tuning adjustment chips add and subtract time properly', (tester) async {
    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    // Initial step timer for Step 1 (22 mins cook time / 5 steps = 264 seconds = 04:24)
    expect(find.text('04:24'), findsOneWidget);

    // Tap +1 min
    await tester.tap(find.text('+1 min'));
    await tester.pump();
    expect(find.text('05:24'), findsOneWidget);

    // Tap +30s
    await tester.tap(find.text('+30s'));
    await tester.pump();
    expect(find.text('05:54'), findsOneWidget);

    // Tap -1 min
    await tester.tap(find.text('-1 min'));
    await tester.pump();
    expect(find.text('04:54'), findsOneWidget);
  });

  testWidgets('Step navigation moves through steps and extracts step-specific time', (tester) async {
    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    expect(find.textContaining('Step 1 of 5'), findsOneWidget);

    // Tap Next Step -> Step 2 has "4 minutes" in instruction text
    await tester.tap(find.text('Next Step'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Step 2 of 5'), findsOneWidget);
    expect(find.text('04:00'), findsOneWidget); // Extracted 4 minutes!
    expect(find.text('Previous'), findsOneWidget);

    // Tap Previous -> returns to Step 1
    await tester.tap(find.text('Previous'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Step 1 of 5'), findsOneWidget);
  });
}
