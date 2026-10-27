import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../providers/recipe_providers.dart';
import '../../../../shared/widgets/cooking_timer_sheet.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/favorite_button.dart';
import '../../../../shared/widgets/glass_card.dart';

class RecipeDetailScreen extends ConsumerStatefulWidget {
  final String recipeId;

  const RecipeDetailScreen({super.key, required this.recipeId});

  @override
  ConsumerState<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends ConsumerState<RecipeDetailScreen> {
  int _servingAdjustment = 0;
  final Set<int> _checkedIngredients = {};

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final recipeAsync = ref.watch(recipeDetailProvider(widget.recipeId));

    return Scaffold(
      body: recipeAsync.when(
        data: (recipe) {
          if (recipe == null) {
            return Scaffold(
              appBar: AppBar(
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_rounded),
                  onPressed: () =>
                      context.canPop() ? context.pop() : context.go('/recipes'),
                ),
              ),
              body: EmptyState(
                icon: Icons.restaurant_rounded,
                title: 'Recipe not found',
                message:
                    'The recipe "${widget.recipeId}" could not be located in our cookbook.',
                actionLabel: 'Browse All Recipes',
                onAction: () => context.go('/recipes'),
              ),
            );
          }

          final currentServings = (recipe.servings + _servingAdjustment).clamp(
            1,
            24,
          );

          return CustomScrollView(
            slivers: [
              // Hero Image Header Sliver
              SliverAppBar(
                expandedHeight: 380,
                pinned: true,
                elevation: 0,
                backgroundColor: isDark
                    ? AppColors.deepSurface
                    : AppColors.warmCream,
                leading: Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: Center(
                    child: GlassSurface(
                      borderRadius: 30,
                      blur: 16,
                      padding: const EdgeInsets.all(8),
                      backgroundColor: Colors.black.withValues(alpha: 0.35),
                      borderColor: Colors.white.withValues(alpha: 0.3),
                      onTap: () {
                        if (context.canPop()) {
                          context.pop();
                        } else {
                          context.go('/recipes');
                        }
                      },
                      child: const Icon(
                        Icons.arrow_back_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
                actions: [
                  // Share Button
                  GlassSurface(
                    borderRadius: 30,
                    blur: 16,
                    padding: const EdgeInsets.all(8),
                    backgroundColor: Colors.black.withValues(alpha: 0.35),
                    borderColor: Colors.white.withValues(alpha: 0.3),
                    onTap: () {
                      Clipboard.setData(
                        ClipboardData(
                          text:
                              'CookMate Recipe: ${recipe.title} - Total Time: ${recipe.totalMinutes}m',
                        ),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Recipe details copied to clipboard! 📋',
                          ),
                          backgroundColor: AppColors.forestGreen,
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    child: const Icon(
                      Icons.share_outlined,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Favorite Button
                  FavoriteButton(recipeId: recipe.id),
                  const SizedBox(width: 16),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      Hero(
                        tag: 'recipe-image-${recipe.id}',
                        child: Image.network(
                          recipe.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: AppColors.forestGreen,
                            child: const Center(
                              child: Icon(
                                Icons.restaurant,
                                size: 64,
                                color: AppColors.citrusLime,
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Gradient Shade
                      Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.black45,
                              Colors.transparent,
                              Colors.black54,
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Recipe Body Content
              SliverToBoxAdapter(
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.deepSurface : AppColors.warmCream,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(32),
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Category Tag & Difficulty Row
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  (isDark
                                          ? AppColors.citrusLime
                                          : AppColors.forestGreen)
                                      .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              recipe.category,
                              style: TextStyle(
                                color: isDark
                                    ? AppColors.citrusLime
                                    : AppColors.forestGreen,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.softCoral.withValues(
                                alpha: 0.15,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              recipe.difficulty,
                              style: const TextStyle(
                                color: AppColors.softCoral,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Title
                      Text(
                        recipe.title,
                        style: theme.textTheme.displayMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Description
                      Text(
                        recipe.description,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: isDark
                              ? AppColors.textLight
                              : AppColors.textDark,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Metrics Highlights Bar (Prep, Cook, Servings, Total)
                      GlassSurface(
                        borderRadius: 22,
                        blur: 14,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 16,
                        ),
                        backgroundColor: isDark
                            ? const Color(0xFF162D25)
                            : Colors.white,
                        borderColor: Colors.black.withValues(alpha: 0.06),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildMetricItem(
                              context,
                              icon: Icons.timer_outlined,
                              label: 'Prep',
                              value: '${recipe.prepMinutes}m',
                            ),
                            _buildDivider(isDark),
                            _buildMetricItem(
                              context,
                              icon: Icons.local_fire_department_outlined,
                              label: 'Cook',
                              value: '${recipe.cookMinutes}m',
                            ),
                            _buildDivider(isDark),
                            _buildMetricItem(
                              context,
                              icon: Icons.schedule_rounded,
                              label: 'Total',
                              value: '${recipe.totalMinutes}m',
                            ),
                            _buildDivider(isDark),
                            _buildMetricItem(
                              context,
                              icon: Icons.people_outline_rounded,
                              label: 'Servings',
                              value: '$currentServings',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Enter Cooking Mode Button
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDark
                              ? AppColors.citrusLime
                              : AppColors.forestGreen,
                          foregroundColor: isDark
                              ? AppColors.deepEmerald
                              : Colors.white,
                          minimumSize: const Size(double.infinity, 54),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          elevation: 3,
                        ),
                        onPressed: () =>
                            CookingTimerSheet.show(context, recipe),
                        icon: const Icon(
                          Icons.play_circle_fill_rounded,
                          size: 24,
                        ),
                        label: const Text(
                          'Enter Cooking Mode & Timer',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Ingredients Header with Servings Stepper
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Ingredients',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          // Servings Stepper (- / +)
                          Container(
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF162D25)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: Colors.black.withValues(alpha: 0.08),
                              ),
                            ),
                            child: Row(
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.remove_rounded,
                                    size: 16,
                                  ),
                                  onPressed: currentServings > 1
                                      ? () =>
                                            setState(() => _servingAdjustment--)
                                      : null,
                                ),
                                Text(
                                  '$currentServings srv',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add_rounded, size: 16),
                                  onPressed: currentServings < 20
                                      ? () =>
                                            setState(() => _servingAdjustment++)
                                      : null,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap items to check them off as you cook',
                        style: theme.textTheme.bodySmall,
                      ),
                      const SizedBox(height: 14),

                      // Interactive Checkable Ingredients List
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: recipe.ingredients.length,
                        itemBuilder: (context, idx) {
                          final isChecked = _checkedIngredients.contains(idx);
                          final ingredient = recipe.ingredients[idx];

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  setState(() {
                                    if (isChecked) {
                                      _checkedIngredients.remove(idx);
                                    } else {
                                      _checkedIngredients.add(idx);
                                    }
                                  });
                                },
                                borderRadius: BorderRadius.circular(14),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isChecked
                                        ? (isDark
                                              ? const Color(0xFF18382A)
                                              : const Color(0xFFEAF5EF))
                                        : (isDark
                                              ? const Color(0xFF162D25)
                                              : Colors.white),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: isChecked
                                          ? (isDark
                                                ? AppColors.citrusLime
                                                : AppColors.forestGreen)
                                          : Colors.black.withValues(
                                              alpha: 0.05,
                                            ),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        isChecked
                                            ? Icons.check_circle_rounded
                                            : Icons
                                                  .radio_button_unchecked_rounded,
                                        color: isChecked
                                            ? (isDark
                                                  ? AppColors.citrusLime
                                                  : AppColors.forestGreen)
                                            : Colors.grey,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          ingredient,
                                          style: TextStyle(
                                            decoration: isChecked
                                                ? TextDecoration.lineThrough
                                                : null,
                                            color: isChecked
                                                ? Colors.grey
                                                : (isDark
                                                      ? AppColors.textLight
                                                      : AppColors.textDark),
                                            fontWeight: FontWeight.w500,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 32),

                      // Instructions Section
                      Text(
                        'Step-by-Step Instructions',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 16),

                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: recipe.instructions.length,
                        itemBuilder: (context, idx) {
                          final step = recipe.instructions[idx];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? AppColors.citrusLime
                                        : AppColors.forestGreen,
                                    shape: BoxShape.circle,
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    '${idx + 1}',
                                    style: TextStyle(
                                      color: isDark
                                          ? AppColors.deepEmerald
                                          : Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Text(
                                    step,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      height: 1.5,
                                      fontSize: 15,
                                      color: isDark
                                          ? AppColors.textLight
                                          : AppColors.textDark,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 24),

                      // Tags wrap
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: recipe.tags.map((tag) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF162D25)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.black.withValues(alpha: 0.06),
                              ),
                            ),
                            child: Text(
                              '#$tag',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? AppColors.citrusLime
                                    : AppColors.forestGreen,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error loading recipe: $err')),
      ),
    );
  }

  Widget _buildMetricItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      children: [
        Icon(
          icon,
          size: 20,
          color: isDark ? AppColors.citrusLime : AppColors.forestGreen,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        ),
        Text(label, style: theme.textTheme.bodySmall?.copyWith(fontSize: 11)),
      ],
    );
  }

  Widget _buildDivider(bool isDark) {
    return Container(
      width: 1,
      height: 30,
      color: isDark
          ? Colors.white.withValues(alpha: 0.1)
          : Colors.black.withValues(alpha: 0.08),
    );
  }
}
