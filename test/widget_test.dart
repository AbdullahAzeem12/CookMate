import 'dart:async';
import 'dart:io';

import 'package:cook_mate/app/app.dart';
import 'package:cook_mate/app/router.dart';
import 'package:cook_mate/features/recipes/domain/models/recipe.dart';
import 'package:cook_mate/shared/widgets/recipe_card.dart';
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

      await tester.pumpWidget(const ProviderScope(child: CookMateApp()));

      await tester.pumpAndSettle();

      // Verify Title and navigation destinations
      expect(find.text('CookMate'), findsWidgets);
      expect(find.text('Categories'), findsOneWidget);
      expect(find.text('Home'), findsWidgets);
      expect(find.text('Explore'), findsWidgets);
      expect(find.text('Search'), findsWidgets);
      expect(find.text('Saved'), findsWidgets);

      // Tap on 'Explore' navigation branch
      await tester.tap(find.byIcon(Icons.explore_outlined));
      await tester.pumpAndSettle();

      // Verify Explore screen rendered without exceptions
      expect(tester.takeException(), isNull);
      expect(find.text('Explore Recipes'), findsOneWidget);

      // Tap on 'Search' navigation branch
      await tester.tap(find.byIcon(Icons.search_outlined));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Find a Dish'), findsOneWidget);

      // Tap on 'Saved' navigation branch
      await tester.tap(find.byIcon(Icons.bookmark_outline_rounded));
      await tester.pumpAndSettle();
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
}
