import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/favorites/presentation/screens/favorites_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/recipes/presentation/screens/explore_screen.dart';
import '../features/recipes/presentation/screens/recipe_detail_screen.dart';
import '../features/search/presentation/search_screen.dart';
import '../features/submission/presentation/screens/submit_recipe_screen.dart';
import '../shared/widgets/empty_state.dart';
import '../shared/widgets/responsive_scaffold.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'root',
);

final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  routes: [
    // Main Stateful Shell Route for Bottom Nav / Nav Rail
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return ResponsiveScaffold(navigationShell: navigationShell);
      },
      branches: [
        // Branch 1: Home
        StatefulShellBranch(
          routes: [
            GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
          ],
        ),
        // Branch 2: Explore
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/recipes',
              builder: (context, state) => const ExploreScreen(),
            ),
          ],
        ),
        // Branch 3: Search with query parameter ?q=
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/search',
              builder: (context, state) {
                final query = state.uri.queryParameters['q'];
                return SearchScreen(initialQuery: query);
              },
            ),
          ],
        ),
        // Branch 4: Favorites
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/favorites',
              builder: (context, state) => const FavoritesScreen(),
            ),
          ],
        ),
      ],
    ),

    // Recipe Detail Direct Route (with :recipeId path parameter)
    GoRoute(
      path: '/recipes/:recipeId',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final recipeId = state.pathParameters['recipeId'] ?? '';
        return RecipeDetailScreen(recipeId: recipeId);
      },
    ),

    // Submit Recipe Direct Route
    GoRoute(
      path: '/submit',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const SubmitRecipeScreen(),
    ),
  ],
  // 404 / Unknown Deep-link fallback handler
  errorBuilder: (context, state) => Scaffold(
    appBar: AppBar(title: const Text('Page Not Found')),
    body: EmptyState(
      icon: Icons.error_outline_rounded,
      title: '404 - Culinary Destination Missing',
      message: 'The link "${state.uri}" does not exist in CookMate.',
      actionLabel: 'Return Home',
      onAction: () => context.go('/'),
    ),
  ),
);
