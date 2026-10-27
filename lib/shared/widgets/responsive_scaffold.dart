import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../features/recipes/presentation/providers/recipe_providers.dart';
import 'glass_card.dart';

class ResponsiveScaffold extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const ResponsiveScaffold({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= AppConstants.mediumBreakpoint;
    final isTablet = width >= AppConstants.compactBreakpoint && !isDesktop;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (isDesktop || isTablet) {
      return Scaffold(
        body: Row(
          children: [
            // Side Navigation Rail
            NavigationRail(
              selectedIndex: navigationShell.currentIndex,
              onDestinationSelected: (index) =>
                  _onDestinationSelected(context, index),
              labelType: NavigationRailLabelType.all,
              backgroundColor: isDark ? const Color(0xFF132821) : Colors.white,
              selectedIconTheme: IconThemeData(
                color: isDark ? AppColors.citrusLime : AppColors.forestGreen,
              ),
              selectedLabelTextStyle: TextStyle(
                color: isDark ? AppColors.citrusLime : AppColors.forestGreen,
                fontWeight: FontWeight.w700,
              ),
              leading: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: AppColors.forestGreen,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.restaurant_menu_rounded,
                        color: AppColors.citrusLime,
                        size: 26,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'CookMate',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
              ),
              trailing: Expanded(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Submit Recipe Action FAB
                        FloatingActionButton.small(
                          heroTag: 'nav-submit-fab',
                          elevation: 2,
                          backgroundColor: AppColors.citrusLime,
                          foregroundColor: AppColors.deepEmerald,
                          tooltip: 'Submit Recipe',
                          onPressed: () => context.push('/submit'),
                          child: const Icon(Icons.add_rounded),
                        ),
                        const SizedBox(height: 16),
                        // Dark/Light Theme Switcher
                        IconButton(
                          tooltip: isDark
                              ? 'Switch to Light Mode'
                              : 'Switch to Dark Mode',
                          icon: Icon(
                            isDark
                                ? Icons.light_mode_rounded
                                : Icons.dark_mode_rounded,
                            color: isDark
                                ? AppColors.citrusLime
                                : AppColors.forestGreen,
                          ),
                          onPressed: () {
                            ref.read(themeModeProvider.notifier).state = isDark
                                ? ThemeMode.light
                                : ThemeMode.dark;
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home_rounded),
                  label: Text('Home'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.explore_outlined),
                  selectedIcon: Icon(Icons.explore_rounded),
                  label: Text('Explore'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.search_outlined),
                  selectedIcon: Icon(Icons.search_rounded),
                  label: Text('Search'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.bookmark_outline_rounded),
                  selectedIcon: Icon(Icons.bookmark_rounded),
                  label: Text('Saved'),
                ),
              ],
            ),
            const VerticalDivider(thickness: 1, width: 1),
            // Expanded content view
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: AppConstants.maxContentWidth,
                  ),
                  child: navigationShell,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Mobile Phone Layout with Translucent Liquid-Glass Bottom Nav
    return Scaffold(
      extendBody: true,
      body: navigationShell,
      bottomNavigationBar: SafeArea(
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: GlassSurface(
            borderRadius: 32,
            blur: 20,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            backgroundColor: isDark
                ? const Color(0xFF132821).withValues(alpha: 0.85)
                : Colors.white.withValues(alpha: 0.90),
            borderColor: isDark
                ? Colors.white.withValues(alpha: 0.12)
                : Colors.black.withValues(alpha: 0.06),
            shadows: [
              BoxShadow(
                color: isDark
                    ? Colors.black45
                    : const Color(0xFF173D31).withValues(alpha: 0.12),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  context,
                  index: 0,
                  icon: Icons.home_outlined,
                  activeIcon: Icons.home_rounded,
                  label: 'Home',
                ),
                _buildNavItem(
                  context,
                  index: 1,
                  icon: Icons.explore_outlined,
                  activeIcon: Icons.explore_rounded,
                  label: 'Explore',
                ),
                // Center Submit Button
                Semantics(
                  label: 'Submit Recipe',
                  button: true,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => context.push('/submit'),
                      borderRadius: BorderRadius.circular(24),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.forestGreen.withValues(
                                alpha: 0.35,
                              ),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.add_rounded,
                          color: AppColors.citrusLime,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ),
                _buildNavItem(
                  context,
                  index: 2,
                  icon: Icons.search_outlined,
                  activeIcon: Icons.search_rounded,
                  label: 'Search',
                ),
                _buildNavItem(
                  context,
                  index: 3,
                  icon: Icons.bookmark_outline_rounded,
                  activeIcon: Icons.bookmark_rounded,
                  label: 'Saved',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
  }) {
    final isSelected = navigationShell.currentIndex == index;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final activeColor = isDark ? AppColors.citrusLime : AppColors.forestGreen;

    return Semantics(
      label: label,
      selected: isSelected,
      button: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _onDestinationSelected(context, index),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    isSelected ? activeIcon : icon,
                    key: ValueKey(isSelected),
                    color: isSelected
                        ? activeColor
                        : theme.textTheme.bodySmall?.color,
                    size: 24,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected
                        ? activeColor
                        : theme.textTheme.bodySmall?.color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _onDestinationSelected(BuildContext context, int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }
}
