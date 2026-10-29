import 'dart:async';
import 'dart:io';

import 'package:cook_mate/app/app.dart';
import 'package:cook_mate/app/router.dart';
import 'package:cook_mate/features/recipes/domain/models/recipe.dart';
import 'package:cook_mate/features/recipes/presentation/providers/recipe_providers.dart';
import 'package:cook_mate/shared/widgets/bounce_tap.dart';
import 'package:cook_mate/shared/widgets/chef_pick_deck.dart';
import 'package:cook_mate/shared/widgets/recipe_card.dart';
import 'package:cook_mate/shared/widgets/trending_recipe_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _TestHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return _createMockImageHttpClient();
  }
}

HttpClient _createMockImageHttpClient() {
  final client = _MockHttpClient();
  return client;
}

class _MockHttpClient implements HttpClient {
  @override
  bool autoUncompress = true;
  @override
  Duration? connectionTimeout;
  @override
  Duration idleTimeout = const Duration(seconds: 15);
  @override
  int? maxConnectionsPerHost;
  @override
  String? userAgent;

  @override
  void addCredentials(
    Uri url,
    String realm,
    HttpClientCredentials credentials,
  ) {}
  @override
  void addProxyCredentials(
    String host,
    int port,
    String realm,
    HttpClientCredentials credentials,
  ) {}
  @override
  set authenticate(
    Future<bool> Function(Uri url, String scheme, String? realm)? f,
  ) {}
  @override
  set authenticateProxy(
    Future<bool> Function(String host, int port, String scheme, String? realm)?
    f,
  ) {}
  @override
  set badCertificateCallback(
    bool Function(X509Certificate cert, String host, int port)? callback,
  ) {}
  @override
  void close({bool force = false}) {}
  @override
  set findProxy(String Function(Uri url)? f) {}

  @override
  Future<HttpClientRequest> getUrl(Uri url) => openUrl('GET', url);
  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async {
    return _MockHttpClientRequest();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockHttpClientRequest implements HttpClientRequest {
  @override
  final HttpHeaders headers = _MockHttpHeaders();

  @override
  Future<HttpClientResponse> close() async {
    return _MockHttpClientResponse();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockHttpHeaders implements HttpHeaders {
  @override
  void add(String name, Object value, {bool preserveHeaderCase = false}) {}
  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {}
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// 1x1 transparent PNG bytes
final List<int> _transparentPng = [
  0x89,
  0x50,
  0x4E,
  0x47,
  0x0D,
  0x0A,
  0x1A,
  0x0A,
  0x00,
  0x00,
  0x00,
  0x0D,
  0x49,
  0x48,
  0x44,
  0x52,
  0x00,
  0x00,
  0x00,
  0x01,
  0x00,
  0x00,
  0x00,
  0x01,
  0x08,
  0x06,
  0x00,
  0x00,
  0x00,
  0x1F,
  0x15,
  0xC4,
  0x89,
  0x00,
  0x00,
  0x00,
  0x0A,
  0x49,
  0x44,
  0x41,
  0x54,
  0x78,
  0x9C,
  0x63,
  0x00,
  0x01,
  0x00,
  0x00,
  0x05,
  0x00,
  0x01,
  0x0D,
  0x0A,
  0x2D,
  0xB4,
  0x00,
  0x00,
  0x00,
  0x00,
  0x49,
  0x45,
  0x4E,
  0x44,
  0xAE,
  0x42,
  0x60,
  0x82,
];

class _MockHttpClientResponse extends Stream<List<int>>
    implements HttpClientResponse {
  @override
  int get statusCode => 200;
  @override
  int get contentLength => _transparentPng.length;
  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;
  @override
  HttpHeaders get headers => _MockHttpHeaders();

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return Stream<List<int>>.fromIterable([_transparentPng]).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUp(() {
    HttpOverrides.global = _TestHttpOverrides();
    SharedPreferences.setMockInitialValues({});
    appRouter.go('/');
  });

  tearDown(() {
    appRouter.go('/');
  });

  testWidgets(
    'RecipeCard does not overflow under compact device dimensions (150w x 198h)',
    (WidgetTester tester) async {
      const sampleRecipe = Recipe(
        id: 'test-recipe-1',
        title: 'Rustic Garden Tomato & Herb Frittata Special',
        description: 'A delicious test frittata description that is long.',
        category: 'Quick & Easy',
        difficulty: 'Easy',
        prepMinutes: 10,
        cookMinutes: 15,
        servings: 2,
        imageUrl: '',
        ingredients: ['2 eggs', '1 tomato'],
        instructions: ['Whisk eggs', 'Cook in pan'],
        tags: ['Breakfast', 'Eggs'],
      );

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 150.0,
                  height: 198.0,
                  child: RecipeCard(recipe: sampleRecipe),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify no assertion or overflow exceptions were thrown during layout
      expect(tester.takeException(), isNull);
      expect(find.textContaining('Rustic Garden'), findsOneWidget);
      expect(find.text('25 min'), findsOneWidget);
    },
  );

  testWidgets(
    'CookMate App boots up and renders main navigation and home content',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2200);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      appRouter.go('/');
      await tester.pumpWidget(const ProviderScope(child: CookMateApp()));

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 500));

      // Verify Title and navigation destinations
      expect(find.text('CookMate'), findsWidgets);
      expect(find.text('Categories'), findsOneWidget);
      expect(find.text('Home'), findsWidgets);
      expect(find.text('Explore'), findsWidgets);
      expect(find.text('Search'), findsWidgets);
      expect(find.text('Saved'), findsWidgets);

      // Tap on 'Explore' navigation branch
      await tester.tap(find.byIcon(Icons.explore_outlined));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify Explore screen rendered without exceptions
      expect(tester.takeException(), isNull);
      expect(find.text('Explore Recipes'), findsOneWidget);

      // Tap on 'Search' navigation branch
      await tester.tap(find.byIcon(Icons.search_outlined));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull);
      expect(find.text('Find a Dish'), findsOneWidget);

      // Tap on 'Saved' navigation branch
      await tester.tap(find.byIcon(Icons.bookmark_outline_rounded));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull);
      expect(find.text('Saved Recipes'), findsOneWidget);
    },
  );

  testWidgets(
    'Explore Screen grid on compact mobile viewport (360x780) renders without pixel overflow',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(720, 1560); // 360 x 780 logical dp (e.g. Huawei MED LX9)
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      appRouter.go('/recipes');
      await tester.pumpWidget(const ProviderScope(child: CookMateApp()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(milliseconds: 500));

      // Verify no exceptions or overflow
      expect(tester.takeException(), isNull);
      expect(find.text('Explore Recipes'), findsOneWidget);
    },
  );

  testWidgets(
    'SplashScreen renders with 3D logo, floating objects, title, and progress bar',
    (WidgetTester tester) async {
      appRouter.go('/splash');
      await tester.pumpWidget(const ProviderScope(child: CookMateApp()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Verify title, tagline, skip button, and floating emojis
      expect(tester.takeException(), isNull);
      expect(find.text('CookMate'), findsWidgets);
      expect(find.text('YOUR PERSONAL KITCHEN COMPANION'), findsOneWidget);
      expect(find.text('Skip'), findsOneWidget);
      expect(find.text('🌿'), findsOneWidget);
      expect(find.text('🍅'), findsOneWidget);

      // Advance time by 3 seconds
      await tester.pump(const Duration(seconds: 3));
      expect(tester.takeException(), isNull);

      // Tap skip to navigate to home
      await tester.tap(find.text('Skip'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 500));

      expect(tester.takeException(), isNull);
      expect(find.text('Categories'), findsOneWidget);
    },
  );

  testWidgets(
    'Horizontal swipe gestures smoothly transition between pages',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2200);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      appRouter.go('/');
      await tester.pumpWidget(const ProviderScope(child: CookMateApp()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Categories'), findsOneWidget);

      // Swipe left to go from Home (index 0) to Explore (index 1)
      await tester.drag(find.byType(PageView), const Offset(-500, 0));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Explore Recipes'), findsOneWidget);

      // Swipe left to go from Explore (index 1) to Search (index 2)
      await tester.drag(find.byType(PageView), const Offset(-500, 0));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Find a Dish'), findsOneWidget);

      // Swipe right to go from Search (index 2) back to Explore (index 1)
      await tester.drag(find.byType(PageView), const Offset(500, 0));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Explore Recipes'), findsOneWidget);
    },
  );

  testWidgets(
    'ChefPickDeck renders in hero position and handles diagonal drag and cycling',
    (WidgetTester tester) async {
      const sampleRecipe1 = Recipe(
        id: 'deck-test-1',
        title: 'Artisanal Truffle Pasta',
        description: 'Rich velvety pasta with black truffle cream sauce.',
        category: 'Quick & Easy',
        difficulty: 'Easy',
        prepMinutes: 10,
        cookMinutes: 15,
        servings: 2,
        imageUrl: 'https://images.unsplash.com/photo-1551183053-bf91a1d81141',
        ingredients: ['Pasta', 'Truffle'],
        instructions: ['Boil', 'Serve'],
        tags: ['Pasta'],
        isChefsPick: true,
      );
      const sampleRecipe2 = Recipe(
        id: 'deck-test-2',
        title: 'Seared Wild Salmon',
        description: 'Crisp skin pan-seared salmon with lemon dill butter.',
        category: 'Healthy Meals',
        difficulty: 'Medium',
        prepMinutes: 12,
        cookMinutes: 10,
        servings: 2,
        imageUrl: 'https://images.unsplash.com/photo-1519708227418-c8fd9a32b7a2',
        ingredients: ['Salmon', 'Dill'],
        instructions: ['Sear', 'Serve'],
        tags: ['Fish'],
        isChefsPick: true,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            allRecipesProvider.overrideWith((ref) => [sampleRecipe1, sampleRecipe2]),
            chefsPickRecipesProvider.overrideWithValue([sampleRecipe1, sampleRecipe2]),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: Padding(
                padding: EdgeInsets.all(20),
                child: ChefPickDeck(),
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(ChefPickDeck), findsOneWidget);
      expect(find.text("CHEF'S PICK"), findsWidgets);
      expect(find.text('Artisanal Truffle Pasta'), findsOneWidget);

      // Perform a diagonal swipe gesture on the ChefPickDeck
      await tester.drag(find.byType(ChefPickDeck), const Offset(200, -60));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // Verify no exceptions and deck cycles smoothly
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'BounceTap widget rapidly compresses on down and snaps back with callback invocation on tap up',
    (WidgetTester tester) async {
      int tapCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: BounceTap(
                shrinkScale: 0.90,
                onTap: () => tapCount++,
                child: const SizedBox(
                  width: 120,
                  height: 60,
                  child: Text('Tap Me'),
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Tap Me'), findsOneWidget);
      expect(tapCount, 0);

      // Press down
      final gesture = await tester.startGesture(tester.getCenter(find.text('Tap Me')));
      await tester.pump(const Duration(milliseconds: 90));

      // Release finger
      await gesture.up();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      // Callback must have been invoked
      expect(tapCount, 1);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'BounceTap with awaitBounce: true completes full rapid bounce before executing onTap',
    (WidgetTester tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: BounceTap(
                shrinkScale: 0.91,
                downDuration: const Duration(milliseconds: 70),
                upDuration: const Duration(milliseconds: 140),
                awaitBounce: true,
                onTap: () => tapped = true,
                child: const SizedBox(
                  width: 100,
                  height: 100,
                  child: Text('Card'),
                ),
              ),
            ),
          ),
        ),
      );

      final gesture = await tester.startGesture(tester.getCenter(find.text('Card')));
      // Quick tap: finger up after only 20ms
      await tester.pump(const Duration(milliseconds: 20));
      await gesture.up();

      // Immediately after tap up, callback should NOT have fired yet because it's still bouncing
      expect(tapped, isFalse);

      // Advance through the remaining down punch & bounce recoil
      await tester.pumpAndSettle();

      // Now the full bounce completed and the callback has fired
      expect(tapped, isTrue);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'TrendingRecipeSlider renders trending recipes with smooth horizontal pop/fade physics',
    (WidgetTester tester) async {
      const sample1 = Recipe(
        id: 'trend-1',
        title: 'Honey Garlic Glazed Salmon',
        description: 'Tender salmon with garlic glaze.',
        category: 'Healthy Meals',
        difficulty: 'Easy',
        prepMinutes: 10,
        cookMinutes: 12,
        servings: 2,
        imageUrl: 'https://images.unsplash.com/photo-1519708227418-c8fd9a32b7a2',
        ingredients: ['Salmon', 'Honey', 'Garlic'],
        instructions: ['Glaze and bake'],
        tags: ['Trending', 'Seafood'],
      );

      const sample2 = Recipe(
        id: 'trend-2',
        title: 'Truffle Mushroom Risotto',
        description: 'Creamy arborio rice with black truffle.',
        category: 'Medium Meals',
        difficulty: 'Medium',
        prepMinutes: 15,
        cookMinutes: 25,
        servings: 3,
        imageUrl: 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c',
        ingredients: ['Arborio', 'Mushrooms', 'Truffle oil'],
        instructions: ['Stir broth gradually'],
        tags: ['Italian'],
      );

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SizedBox(
                height: 280,
                child: TrendingRecipeSlider(
                  recipes: [sample1, sample2],
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byType(TrendingRecipeSlider), findsOneWidget);
      expect(find.text('Honey Garlic Glazed Salmon'), findsOneWidget);

      // Perform horizontal slide drag to exercise pop in/out and fade in/out math
      await tester.drag(find.byType(TrendingRecipeSlider), const Offset(-100, 0));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'ResponsiveScaffold renders without overflow and smoothly transitions when tilting phone between portrait and landscape',
    (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      HttpOverrides.global = _TestHttpOverrides();

      // Start in standard mobile phone portrait (360x800)
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      appRouter.go('/');
      await tester.pumpWidget(
        const ProviderScope(
          child: CookMateApp(),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 500));

      expect(tester.takeException(), isNull);
      expect(find.byType(PageView), findsOneWidget);

      // Simulate user tilting phone horizontally into landscape (800x360)
      tester.view.physicalSize = const Size(800, 360);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 500));

      // Verify no ScrollController assertion or layout overflow occurred
      expect(tester.takeException(), isNull);
      expect(find.byType(NavigationRail), findsOneWidget);

      // Test extreme compact landscape (e.g. 640x300 split-screen)
      tester.view.physicalSize = const Size(640, 300);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull);

      // Tilt back into portrait (360x800)
      tester.view.physicalSize = const Size(360, 800);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Top right chef icon opens Profile screen and asks for sign in, and enables smooth authentication flow',
    (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      HttpOverrides.global = _TestHttpOverrides();

      tester.view.physicalSize = const Size(400, 850);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      appRouter.go('/');
      await tester.pumpWidget(
        const ProviderScope(
          child: CookMateApp(),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 500));

      expect(tester.takeException(), isNull);

      // Find top right chef icon on Home screen
      final chefIconFinder = find.text('👨‍🍳');
      expect(chefIconFinder, findsOneWidget);

      // Tap chef icon to navigate to Profile
      await tester.tap(chefIconFinder);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // Verify Guest Profile Gateway is shown
      expect(find.text('Guest Chef Profile'), findsOneWidget);
      expect(find.text('Sign In to CookMate'), findsOneWidget);
      expect(find.text('Create New Chef Account'), findsOneWidget);

      // Scroll and Tap 'Sign In to CookMate' to open Sign In page
      await tester.ensureVisible(find.text('Sign In to CookMate'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('Sign In to CookMate'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Chef Sign In'), findsOneWidget);
      expect(find.text('Welcome Back, Chef ✨'), findsOneWidget);
      expect(find.text('Master Password'), findsOneWidget);
      expect(find.text('Remember Me'), findsOneWidget);
      expect(find.text('Forgot Password?'), findsOneWidget);

      // Tap Quick Demo Login (Chef Auguste)
      await tester.ensureVisible(find.text('Quick Demo Login (Chef Auguste)'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('Quick Demo Login (Chef Auguste)'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      // Verify authenticated profile dashboard opens
      expect(find.text('Chef Auguste'), findsOneWidget);
      expect(find.text('Master Chef'), findsOneWidget);
      expect(find.text('Sign Out from this Device'), findsOneWidget);
    },
  );
}
