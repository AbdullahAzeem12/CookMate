import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/favorites/presentation/providers/favorites_providers.dart';
import '../../core/theme/app_colors.dart';
import 'glass_card.dart';

class FavoriteButton extends ConsumerStatefulWidget {
  final String recipeId;
  final double size;
  final bool isGlass;

  const FavoriteButton({
    super.key,
    required this.recipeId,
    this.size = 22.0,
    this.isGlass = true,
  });

  @override
  ConsumerState<FavoriteButton> createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends ConsumerState<FavoriteButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isDebouncing = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.35), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.35, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleTap() async {
    if (_isDebouncing) return;
    _isDebouncing = true;
    _controller.forward(from: 0.0);

    await ref
        .read(favoritesNotifierProvider.notifier)
        .toggleFavorite(widget.recipeId);

    if (mounted) {
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) _isDebouncing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final favoriteIdsAsync = ref.watch(favoritesNotifierProvider);
    final isFavorite =
        favoriteIdsAsync.value?.contains(widget.recipeId) ?? false;

    final heartWidget = ScaleTransition(
      scale: _scaleAnimation,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 180),
        transitionBuilder: (child, anim) =>
            ScaleTransition(scale: anim, child: child),
        child: Icon(
          isFavorite ? Icons.favorite_rounded : Icons.favorite_outline_rounded,
          key: ValueKey(isFavorite),
          color: isFavorite ? AppColors.softCoral : Colors.white,
          size: widget.size,
        ),
      ),
    );

    if (!widget.isGlass) {
      return IconButton(
        tooltip: isFavorite ? 'Remove from favorites' : 'Add to favorites',
        onPressed: _handleTap,
        icon: heartWidget,
      );
    }

    return Semantics(
      label: isFavorite
          ? 'Remove recipe from favorites'
          : 'Save recipe to favorites',
      button: true,
      child: GlassSurface(
        borderRadius: 50,
        blur: 16,
        padding: const EdgeInsets.all(8),
        backgroundColor: isFavorite
            ? AppColors.softCoral.withValues(alpha: 0.25)
            : Colors.black.withValues(alpha: 0.28),
        borderColor: Colors.white.withValues(alpha: 0.35),
        onTap: _handleTap,
        child: heartWidget,
      ),
    );
  }
}
