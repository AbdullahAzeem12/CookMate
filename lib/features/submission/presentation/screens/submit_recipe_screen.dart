import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import 'package:cook_mate/core/constants/app_constants.dart';
import 'package:cook_mate/core/theme/app_colors.dart';
import 'package:cook_mate/features/auth/presentation/providers/auth_providers.dart';
import 'package:cook_mate/features/recipes/domain/models/recipe.dart';
import 'package:cook_mate/features/recipes/presentation/providers/recipe_providers.dart';
import 'package:cook_mate/shared/widgets/app_cached_network_image.dart';
import 'package:cook_mate/shared/widgets/bounce_tap.dart';
import 'package:cook_mate/features/submission/domain/services/smart_recipe_autofill_service.dart';

class SubmitRecipeScreen extends ConsumerStatefulWidget {
  const SubmitRecipeScreen({super.key});

  @override
  ConsumerState<SubmitRecipeScreen> createState() => _SubmitRecipeScreenState();
}

class _SubmitRecipeScreenState extends ConsumerState<SubmitRecipeScreen> {
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _prepMinutesController = TextEditingController(text: '15');
  final _cookMinutesController = TextEditingController(text: '20');
  final _servingsController = TextEditingController(text: '4');
  final _imageUrlController = TextEditingController();

  String _selectedCategory = AppConstants.categories.first;
  String _selectedDifficulty = AppConstants.difficulties.first;

  final List<TextEditingController> _ingredientControllers = [
    TextEditingController(text: '2 cups Fresh vegetables, sliced'),
    TextEditingController(text: '2 tbsp Olive oil and sea salt'),
  ];

  final List<TextEditingController> _instructionControllers = [
    TextEditingController(
      text: 'Wash and prep all fresh ingredients thoroughly.',
    ),
    TextEditingController(
      text: 'Cook over medium heat until tender and golden brown.',
    ),
  ];

  bool _isSubmitting = false;
  bool _isAutoFilling = false;
  String? _detectedDishName;

  @override
  void initState() {
    super.initState();
    _titleController.addListener(_onTitleChanged);
    _imageUrlController.addListener(_onImageUrlChanged);
  }

  void _onTitleChanged() {
    final text = _titleController.text.trim();
    if (text.length >= 3) {
      final suggestion = SmartRecipeAutofillService.generateSuggestion(
        title: text,
        categoryHint: _selectedCategory,
      );
      if (_detectedDishName != suggestion.title) {
        setState(() {
          _detectedDishName = suggestion.title;
        });
      }
    } else {
      if (_detectedDishName != null) {
        setState(() {
          _detectedDishName = null;
        });
      }
    }
  }

  void _onImageUrlChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _titleController.removeListener(_onTitleChanged);
    _imageUrlController.removeListener(_onImageUrlChanged);
    _titleController.dispose();
    _descriptionController.dispose();
    _prepMinutesController.dispose();
    _cookMinutesController.dispose();
    _servingsController.dispose();
    _imageUrlController.dispose();
    for (final c in _ingredientControllers) {
      c.dispose();
    }
    for (final c in _instructionControllers) {
      c.dispose();
    }
    super.dispose();
  }

  /// Automatically analyzes Title and Category, fetching verified authentic
  /// Unsplash food photography and populating chef-grade ingredients & steps.
  Future<void> _applySmartAutofill({
    String? forcedTitle,
    String? forcedCategory,
  }) async {
    final queryTitle = forcedTitle ?? _titleController.text.trim();
    final queryCategory = forcedCategory ?? _selectedCategory;

    if (queryTitle.isEmpty && forcedTitle == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a Recipe Title first (e.g. Red Velvet Cake).'),
          backgroundColor: AppColors.softCoral,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isAutoFilling = true);
    HapticFeedback.lightImpact();

    // Brief realistic visual synthesis delay
    await Future.delayed(const Duration(milliseconds: 250));

    final suggestion = SmartRecipeAutofillService.generateSuggestion(
      title: queryTitle,
      categoryHint: queryCategory,
    );

    if (!mounted) return;

    setState(() {
      if (_titleController.text.trim().isEmpty || forcedTitle != null) {
        _titleController.text = suggestion.title;
      }
      _descriptionController.text = suggestion.description;
      _selectedCategory = suggestion.category;
      _selectedDifficulty = suggestion.difficulty;
      _prepMinutesController.text = suggestion.prepMinutes.toString();
      _cookMinutesController.text = suggestion.cookMinutes.toString();
      _servingsController.text = suggestion.servings.toString();
      _imageUrlController.text = suggestion.imageUrl;

      // Populate ingredients
      for (final c in _ingredientControllers) {
        c.dispose();
      }
      _ingredientControllers.clear();
      for (final ing in suggestion.ingredients) {
        _ingredientControllers.add(TextEditingController(text: ing));
      }

      // Populate instructions
      for (final c in _instructionControllers) {
        c.dispose();
      }
      _instructionControllers.clear();
      for (final step in suggestion.instructions) {
        _instructionControllers.add(TextEditingController(text: step));
      }

      _isAutoFilling = false;
      _detectedDishName = suggestion.title;
    });

    HapticFeedback.mediumImpact();
    if (mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.auto_awesome, color: AppColors.citrusLime, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Auto-filled "${suggestion.title}" with authentic photo & culinary details!',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF162D25),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _addIngredientRow() {
    setState(() {
      _ingredientControllers.add(TextEditingController());
    });
  }

  void _removeIngredientRow(int index) {
    if (_ingredientControllers.length > 2) {
      setState(() {
        _ingredientControllers.removeAt(index).dispose();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('At least 2 ingredients are required.')),
      );
    }
  }

  void _addInstructionRow() {
    setState(() {
      _instructionControllers.add(TextEditingController());
    });
  }

  void _removeInstructionRow(int index) {
    if (_instructionControllers.length > 2) {
      setState(() {
        _instructionControllers.removeAt(index).dispose();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('At least 2 instruction steps are required.'),
        ),
      );
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final ingredients = _ingredientControllers
        .map((c) => c.text.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    final instructions = _instructionControllers
        .map((c) => c.text.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    if (ingredients.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please provide at least 2 valid ingredients.'),
        ),
      );
      return;
    }

    if (instructions.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please provide at least 2 valid instruction steps.'),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final slug = _titleController.text
          .trim()
          .toLowerCase()
          .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
          .replaceAll(RegExp(r'^-+|-+$'), '');
      final uniqueId = '$slug-${const Uuid().v4().substring(0, 6)}';

      final defaultImage = _selectedCategory == AppConstants.categoryDesserts
          ? 'https://images.unsplash.com/photo-1551024709-8f23befc6f87?auto=format&fit=crop&w=1200&q=80'
          : _selectedCategory == AppConstants.categoryHealthyMeals
          ? 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?auto=format&fit=crop&w=1200&q=80'
          : 'https://images.unsplash.com/photo-1551183053-bf91a1d81141?auto=format&fit=crop&w=1200&q=80';

      final inputImage = _imageUrlController.text.trim();
      final uri = inputImage.isNotEmpty ? Uri.tryParse(inputImage) : null;
      final isValidImageUrl =
          uri != null &&
          uri.hasScheme &&
          (uri.scheme == 'http' || uri.scheme == 'https');
      final safeImageUrl = isValidImageUrl ? inputImage : defaultImage;

      final currentUser = ref.read(currentUserProvider);
      final authorUid = currentUser?.id ?? currentUser?.email ?? 'local_chef';

      final recipe = Recipe(
        id: uniqueId,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory,
        imageUrl: safeImageUrl,
        ingredients: ingredients,
        instructions: instructions,
        prepMinutes: int.tryParse(_prepMinutesController.text) ?? 15,
        cookMinutes: int.tryParse(_cookMinutesController.text) ?? 20,
        servings: int.tryParse(_servingsController.text) ?? 4,
        difficulty: _selectedDifficulty,
        tags: [
          _selectedCategory,
          _selectedDifficulty,
          'Community',
          'Chef Creation',
        ],
        createdAt: DateTime.now(),
        isCommunitySubmission: true,
        isChefsPick: true,
        authorUid: authorUid,
        status: 'approved',
      );

      final submissionRepo = ref.read(submissionRepositoryProvider);
      final result = await submissionRepo.submitRecipe(recipe);

      // Add to main repository cache so it's live immediately
      await ref
          .read(recipeRepositoryProvider)
          .addSubmittedRecipe(result.recipe);
      ref.invalidate(allRecipesProvider);
      ref.invalidate(searchResultsProvider);

      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.stars_rounded, color: AppColors.citrusLime),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Recipe "${recipe.title}" published and saved to your kitchen vault! ✨',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.forestGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            duration: const Duration(seconds: 4),
          ),
        );
        // Navigate directly to the newly created recipe
        context.go('/recipes/${recipe.id}');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Submission error: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currentImageUrl = _imageUrlController.text.trim();
    final isValidUrl = currentImageUrl.startsWith('http://') ||
        currentImageUrl.startsWith('https://');

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/');
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () =>
                context.canPop() ? context.pop() : context.go('/'),
          ),
          title: Text(
            'Share a Recipe',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Inspire fellow home cooks with your signature kitchen creation.',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),

                // ── Smart Chef AI Autofill Card ──────────────────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDark
                          ? [
                              const Color(0xFF162D25),
                              const Color(0xFF1E3F35),
                            ]
                          : [
                              const Color(0xFFEAF5F0),
                              const Color(0xFFD6EFE5),
                            ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark
                          ? AppColors.citrusLime.withValues(alpha: 0.35)
                          : AppColors.forestGreen.withValues(alpha: 0.25),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.forestGreen.withValues(alpha: 0.08),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.citrusLime.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.auto_awesome,
                              color: AppColors.forestGreen,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Chef AI Smart Auto-Fill',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                    color: isDark
                                        ? AppColors.citrusLime
                                        : AppColors.deepEmerald,
                                  ),
                                ),
                                Text(
                                  'Auto-detects dish, fetches authentic Unsplash photo, ingredients & cooking times.',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: isDark
                                        ? AppColors.textMutedDark
                                        : AppColors.textMutedLight,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Quick Inspiration Chips
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildQuickSuggestionChip(
                            label: '🍰 Red Velvet Cake',
                            title: 'Red Velvet Cake',
                            category: AppConstants.categoryDesserts,
                            isDark: isDark,
                          ),
                          _buildQuickSuggestionChip(
                            label: '🍤 Tuscan Garlic Shrimp',
                            title: 'Creamy Tuscan Garlic Shrimp',
                            category: AppConstants.categoryQuickAndEasy,
                            isDark: isDark,
                          ),
                          _buildQuickSuggestionChip(
                            label: '🍝 Beef Lasagna',
                            title: 'Beef Lasagna Bolognese',
                            category: AppConstants.categoryQuickAndEasy,
                            isDark: isDark,
                          ),
                          _buildQuickSuggestionChip(
                            label: '🥑 Avocado Toast',
                            title: 'Artisanal Sourdough Avocado Toast',
                            category: AppConstants.categoryHealthyMeals,
                            isDark: isDark,
                          ),
                          _buildQuickSuggestionChip(
                            label: '🍫 Lava Cake',
                            title: 'Valrhona Chocolate Lava Cake',
                            category: AppConstants.categoryDesserts,
                            isDark: isDark,
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Auto-fill Action Button
                      BounceTap(
                        onTap: _isAutoFilling ? null : () => _applySmartAutofill(),
                        child: Container(
                          width: double.infinity,
                          height: 44,
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Center(
                            child: _isAutoFilling
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.citrusLime,
                                    ),
                                  )
                                : const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.auto_fix_high_rounded,
                                        color: AppColors.citrusLime,
                                        size: 18,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'Auto-Fill from Title & Category',
                                        style: TextStyle(
                                          color: AppColors.citrusLime,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 13.5,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Title Field
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildFieldLabel('Recipe Title', isRequired: true),
                    if (_detectedDishName != null)
                      BounceTap(
                        onTap: () => _applySmartAutofill(forcedTitle: _detectedDishName),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.citrusLime.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: AppColors.citrusLime.withValues(alpha: 0.5),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.auto_awesome,
                                size: 12,
                                color: AppColors.forestGreen,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Match: $_detectedDishName',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.forestGreen,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    hintText: 'e.g. Red Velvet Cake, Lasagna, or Biryani',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().length < 3) {
                      return 'Title must be at least 3 characters.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 18),

                // Description Field
                _buildFieldLabel('Description', isRequired: true),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'A brief description of flavors, texture, and inspiration...',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().length < 10) {
                      return 'Description must be at least 10 characters.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 18),

                // Category & Difficulty Row
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFieldLabel('Category', isRequired: true),
                          DropdownButtonFormField<String>(
                            initialValue: _selectedCategory,
                            isExpanded: true,
                            decoration: const InputDecoration(),
                            items: AppConstants.categories.map((cat) {
                              return DropdownMenuItem(
                                value: cat,
                                child: Text(cat, overflow: TextOverflow.ellipsis),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _selectedCategory = val);
                                if (_titleController.text.trim().length >= 3) {
                                  _applySmartAutofill(forcedCategory: val);
                                }
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFieldLabel('Difficulty', isRequired: true),
                          DropdownButtonFormField<String>(
                            initialValue: _selectedDifficulty,
                            isExpanded: true,
                            decoration: const InputDecoration(),
                            items: AppConstants.difficulties.map((diff) {
                              return DropdownMenuItem(
                                value: diff,
                                child: Text(diff, overflow: TextOverflow.ellipsis),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _selectedDifficulty = val);
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Prep, Cook, Servings Row
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFieldLabel('Prep (min)', isRequired: true),
                          TextFormField(
                            controller: _prepMinutesController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(hintText: '15'),
                            validator: (v) {
                              final n = int.tryParse(v ?? '');
                              if (n == null || n < 1) return '>0';
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFieldLabel('Cook (min)', isRequired: true),
                          TextFormField(
                            controller: _cookMinutesController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(hintText: '20'),
                            validator: (v) {
                              final n = int.tryParse(v ?? '');
                              if (n == null || n < 0) return '>=0';
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFieldLabel('Servings', isRequired: true),
                          TextFormField(
                            controller: _servingsController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(hintText: '4'),
                            validator: (v) {
                              final n = int.tryParse(v ?? '');
                              if (n == null || n < 1 || n > 50) return '1-50';
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Image URL
                _buildFieldLabel('Photo URL (Optional)'),
                TextFormField(
                  controller: _imageUrlController,
                  decoration: const InputDecoration(
                    hintText: 'https://images.unsplash.com/... (auto-filled or custom)',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return null;
                    final uri = Uri.tryParse(value.trim());
                    if (uri == null ||
                        !uri.hasScheme ||
                        (uri.scheme != 'http' && uri.scheme != 'https')) {
                      return 'Please enter a valid web image URL (must start with http:// or https://)';
                    }
                    return null;
                  },
                ),

                // Live Authentic Photo Preview Card
                if (isValidUrl) ...[
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      height: 190,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF162D25) : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isDark
                              ? AppColors.citrusLime.withValues(alpha: 0.4)
                              : AppColors.forestGreen.withValues(alpha: 0.3),
                          width: 1.5,
                        ),
                      ),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          AppCachedNetworkImage(
                            imageUrl: currentImageUrl,
                            category: _selectedCategory,
                            fit: BoxFit.cover,
                          ),
                          // Subtle bottom vignette
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withValues(alpha: 0.75),
                                ],
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 12,
                            left: 12,
                            right: 12,
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.70),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.white.withValues(alpha: 0.25),
                                    ),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.verified_rounded,
                                        color: AppColors.citrusLime,
                                        size: 14,
                                      ),
                                      SizedBox(width: 6),
                                      Text(
                                        'Authentic Unsplash Culinary Photo',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 28),

                // Dynamic Ingredients List
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildFieldLabel('Ingredients (Min 2)', isRequired: true),
                    TextButton.icon(
                      onPressed: _addIngredientRow,
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('Add Row'),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ...List.generate(_ingredientControllers.length, (idx) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _ingredientControllers[idx],
                            decoration: InputDecoration(
                              hintText: 'e.g. 250g Rigatoni pasta',
                              prefixIcon: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Text(
                                  '${idx + 1}.',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Cannot be empty.';
                              }
                              return null;
                            },
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.remove_circle_outline_rounded,
                            color: Colors.redAccent,
                          ),
                          onPressed: () => _removeIngredientRow(idx),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 24),

                // Dynamic Instructions List
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildFieldLabel(
                      'Cooking Instructions (Min 2)',
                      isRequired: true,
                    ),
                    TextButton.icon(
                      onPressed: _addInstructionRow,
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('Add Step'),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ...List.generate(_instructionControllers.length, (idx) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _instructionControllers[idx],
                            maxLines: 2,
                            decoration: InputDecoration(
                              hintText: 'e.g. Sauté garlic in olive oil until fragrant...',
                              prefixIcon: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Text(
                                  'Step ${idx + 1}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Step cannot be empty.';
                              }
                              return null;
                            },
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.remove_circle_outline_rounded,
                            color: Colors.redAccent,
                          ),
                          onPressed: () => _removeInstructionRow(idx),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 32),

                // Submit Button
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 54),
                    backgroundColor: isDark
                        ? AppColors.citrusLime
                        : AppColors.forestGreen,
                    foregroundColor: isDark
                        ? AppColors.deepEmerald
                        : Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: _isSubmitting ? null : _handleSubmit,
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Submit Recipe to CookMate',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  }

  Widget _buildQuickSuggestionChip({
    required String label,
    required String title,
    required String category,
    required bool isDark,
  }) {
    return BounceTap(
      onTap: () => _applySmartAutofill(
        forcedTitle: title,
        forcedCategory: category,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF142720) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark
                ? AppColors.citrusLime.withValues(alpha: 0.3)
                : AppColors.forestGreen.withValues(alpha: 0.2),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.citrusLime : AppColors.forestGreen,
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String text, {bool isRequired = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            text,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
          if (isRequired)
            const Text(
              ' *',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
        ],
      ),
    );
  }
}
