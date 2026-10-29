import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../features/recipes/presentation/providers/recipe_providers.dart';
import 'app_logo_badge.dart';
import 'bounce_tap.dart';
import 'glass_card.dart';

class ResponsiveScaffold extends ConsumerStatefulWidget {
  final StatefulNavigationShell navigationShell;
  final List<Widget>? children;

  const ResponsiveScaffold({
    super.key,
    required this.navigationShell,
    this.children,
  });

  @override
  ConsumerState<ResponsiveScaffold> createState() => _ResponsiveScaffoldState();
}

class _ResponsiveScaffoldState extends ConsumerState<ResponsiveScaffold> {
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      initialPage: widget.navigationShell.currentIndex,
    );
  }

  @override
  void didUpdateWidget(covariant ResponsiveScaffold oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.navigationShell.currentIndex !=
        oldWidget.navigationShell.currentIndex) {
      if (_pageController.hasClients &&
          _pageController.positions.length == 1 &&
          _pageController.positions.first.haveDimensions) {
        try {
          final currentPage = _pageController.page?.round();
          if (currentPage != null &&
              currentPage != widget.navigationShell.currentIndex) {
            _pageController.animateToPage(
              widget.navigationShell.currentIndex,
              duration: const Duration(milliseconds: 360),
              curve: Curves.easeOutCubic,
            );
          }
        } catch (_) {}
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onDestinationSelected(BuildContext context, int index) {
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
    if (_pageController.hasClients &&
        _pageController.positions.length == 1 &&
        _pageController.positions.first.haveDimensions) {
      try {
        if (_pageController.page?.round() != index) {
          _pageController.jumpToPage(index);
        }
      } catch (_) {}
    }
  }

  DateTime? _lastBackPressTime;

  void _handleSystemBack() {
    // 1. If currently on a non-home tab (Explore, Search, Saved), smoothly navigate back to Home (index 0)
    if (widget.navigationShell.currentIndex != 0) {
      _onDestinationSelected(context, 0);
      return;
    }

    // 2. Already on Home tab: Professional double-back-to-exit pattern to prevent accidental app exits
    final now = DateTime.now();
    if (_lastBackPressTime == null ||
        now.difference(_lastBackPressTime!) > const Duration(seconds: 2)) {
      _lastBackPressTime = now;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.info_outline_rounded,
                color: AppColors.citrusLime,
                size: 20,
              ),
              SizedBox(width: 10),
              Text(
                'Press back again to exit CookMate',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  fontSize: 13.5,
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.forestGreen,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          margin: const EdgeInsets.fromLTRB(20, 0, 20, 92),
        ),
      );
    } else {
      // Exit app cleanly
      SystemNavigator.pop();
    }
  }

  double _safePageOffset(int index) {
    if (_pageController.hasClients &&
        _pageController.positions.length == 1 &&
        _pageController.positions.first.haveDimensions) {
      try {
        final page = _pageController.page;
        if (page != null) {
          return page - index;
        }
      } catch (_) {}
    }
    return (widget.navigationShell.currentIndex - index).toDouble();
  }

  Widget _buildMainBody() {
    if (widget.children == null || widget.children!.isEmpty) {
      return widget.navigationShell;
    }

    return PageView.custom(
      key: const PageStorageKey<String>('cookmate-main-responsive-pageview'),
      controller: _pageController,
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      onPageChanged: (index) {
        if (index != widget.navigationShell.currentIndex) {
          widget.navigationShell.goBranch(index);
        }
      },
      childrenDelegate: SliverChildBuilderDelegate(
        (context, index) {
          final child = widget.children![index];
          return _KeepAlivePageWrapper(
            child: AnimatedBuilder(
              animation: _pageController,
              builder: (context, animChild) {
                final pageOffset = _safePageOffset(index);
                final clamped = pageOffset.clamp(-1.0, 1.0);
                final scale = 1.0 - (clamped.abs() * 0.04);
                final opacity = (1.0 - (clamped.abs() * 0.25)).clamp(0.0, 1.0);

                return Transform.scale(
                  scale: scale,
                  child: Opacity(
                    opacity: opacity,
                    child: animChild,
                  ),
                );
              },
              child: child,
            ),
          );
        },
        childCount: widget.children!.length,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width = size.width;
    final height = size.height;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Responsive screen classification
    final isDesktop = width >= AppConstants.mediumBreakpoint && height >= 550;
    final isCompactLandscape = width >= 480 && height < 500;
    final isTablet =
        (width >= AppConstants.compactBreakpoint || isCompactLandscape) &&
        !isDesktop;

    final Widget content;

    if (isDesktop || isTablet) {
      content = Scaffold(
        body: Row(
          children: [
            // Side Navigation Rail wrapped in scrollable LayoutBuilder
            // to GUARANTEE zero pixel overflow across every screen size and tilt
            LayoutBuilder(
              builder: (context, railConstraints) {
                final availableHeight = railConstraints.maxHeight;
                final isHeightConstrained = availableHeight < 480;

                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: availableHeight),
                    child: IntrinsicHeight(
                      child: NavigationRail(
                        selectedIndex: widget.navigationShell.currentIndex,
                        onDestinationSelected: (index) =>
                            _onDestinationSelected(context, index),
                        labelType: isHeightConstrained
                            ? NavigationRailLabelType.none
                            : NavigationRailLabelType.all,
                        backgroundColor: isDark
                            ? const Color(0xFF132821)
                            : Colors.white,
                        selectedIconTheme: IconThemeData(
                          color: isDark
                              ? AppColors.citrusLime
                              : AppColors.forestGreen,
                        ),
                        selectedLabelTextStyle: TextStyle(
                          color: isDark
                              ? AppColors.citrusLime
                              : AppColors.forestGreen,
                          fontWeight: FontWeight.w700,
                        ),
                        leading: Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: isHeightConstrained ? 8 : 16,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AppLogoBadge(
                                size: isHeightConstrained ? 32 : 44,
                                margin: EdgeInsets.only(
                                  bottom: isHeightConstrained ? 4 : 8,
                                ),
                              ),
                              if (!isHeightConstrained)
                                const Text(
                                  'CookMate',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        trailing: Padding(
                          padding: EdgeInsets.only(
                            top: isHeightConstrained ? 6 : 16,
                            bottom: isHeightConstrained ? 8 : 20,
                          ),
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
                                child: const Icon(Icons.add_rounded, size: 20),
                              ),
                              SizedBox(height: isHeightConstrained ? 6 : 12),
                              // Dark/Light Theme Switcher
                              IconButton(
                                iconSize: isHeightConstrained ? 20 : 24,
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
                                  ref
                                      .read(themeModeProvider.notifier)
                                      .state = isDark
                                      ? ThemeMode.light
                                      : ThemeMode.dark;
                                },
                              ),
                            ],
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
                    ),
                  ),
                );
              },
            ),
            const VerticalDivider(thickness: 1, width: 1),
            // Expanded content view
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: AppConstants.maxContentWidth,
                  ),
                  child: _buildMainBody(),
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      // Mobile Phone Layout with Translucent Liquid-Glass Bottom Nav
      content = Scaffold(
      extendBody: true,
      body: _buildMainBody(),
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
              children: [
                Expanded(
                  child: _buildNavItem(
                    context,
                    index: 0,
                    icon: Icons.home_outlined,
                    activeIcon: Icons.home_rounded,
                    label: 'Home',
                  ),
                ),
                Expanded(
                  child: _buildNavItem(
                    context,
                    index: 1,
                    icon: Icons.explore_outlined,
                    activeIcon: Icons.explore_rounded,
                    label: 'Explore',
                  ),
                ),
                // Center Submit Button
                Semantics(
                  label: 'Submit Recipe',
                  button: true,
                  child: BounceTap(
                    onTap: () => context.push('/submit'),
                    shrinkScale: 0.88,
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.all(10),
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
                        size: 22,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: _buildNavItem(
                    context,
                    index: 2,
                    icon: Icons.search_outlined,
                    activeIcon: Icons.search_rounded,
                    label: 'Search',
                  ),
                ),
                Expanded(
                  child: _buildNavItem(
                    context,
                    index: 3,
                    icon: Icons.bookmark_outline_rounded,
                    activeIcon: Icons.bookmark_rounded,
                    label: 'Saved',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleSystemBack();
      },
      child: content,
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
  }) {
    final isSelected = widget.navigationShell.currentIndex == index;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final activeColor = isDark ? AppColors.citrusLime : AppColors.forestGreen;

    return Semantics(
      label: label,
      selected: isSelected,
      button: true,
      child: BounceTap(
        onTap: () => _onDestinationSelected(context, index),
        shrinkScale: 0.90,
        child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
            decoration: BoxDecoration(
              color: isSelected
                  ? activeColor.withValues(alpha: isDark ? 0.15 : 0.10)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  transitionBuilder: (child, animation) {
                    return ScaleTransition(scale: animation, child: child);
                  },
                  child: Icon(
                    isSelected ? activeIcon : icon,
                    key: ValueKey(isSelected),
                    color: isSelected
                        ? activeColor
                        : theme.textTheme.bodySmall?.color,
                    size: 22,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected
                        ? activeColor
                        : theme.textTheme.bodySmall?.color,
                  ),
                ),
                const SizedBox(height: 2),
                // Glowing dot indicator under active tab
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutCubic,
                  width: isSelected ? 4 : 0,
                  height: isSelected ? 4 : 0,
                  decoration: BoxDecoration(
                    color: activeColor,
                    shape: BoxShape.circle,
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: activeColor.withValues(alpha: 0.6),
                              blurRadius: 4,
                              spreadRadius: 1,
                            ),
                          ]
                        : null,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
  }
}

class _KeepAlivePageWrapper extends StatefulWidget {
  final Widget child;

  const _KeepAlivePageWrapper({required this.child});

  @override
  State<_KeepAlivePageWrapper> createState() => _KeepAlivePageWrapperState();
}

class _KeepAlivePageWrapperState extends State<_KeepAlivePageWrapper>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
