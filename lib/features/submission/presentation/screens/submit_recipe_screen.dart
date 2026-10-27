import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:cook_mate/core/constants/app_constants.dart';
import 'package:cook_mate/core/theme/app_colors.dart';
import 'package:cook_mate/features/recipes/domain/models/recipe.dart';
import 'package:cook_mate/features/recipes/presentation/providers/recipe_providers.dart';

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

  @override
  void dispose() {
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
          : 'https://images.unsplash.com/photo-1621996346565-e3d5d6281691?auto=format&fit=crop&w=1200&q=80';

      final recipe = Recipe(
        id: uniqueId,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory,
        imageUrl: _imageUrlController.text.trim().isNotEmpty
            ? _imageUrlController.text.trim()
            : defaultImage,
        ingredients: ingredients,
        instructions: instructions,
        prepMinutes: int.tryParse(_prepMinutesController.text) ?? 15,
        cookMinutes: int.tryParse(_cookMinutesController.text) ?? 20,
        servings: int.tryParse(_servingsController.text) ?? 4,
        difficulty: _selectedDifficulty,
        tags: [_selectedCategory, _selectedDifficulty, 'Community'],
        createdAt: DateTime.now(),
        isCommunitySubmission: true,
      );

      final submissionRepo = ref.read(submissionRepositoryProvider);
      final result = await submissionRepo.submitRecipe(recipe);

      // Add to main repository cache so it's live immediately
      await ref
          .read(recipeRepositoryProvider)
          .addSubmittedRecipe(result.recipe);
      ref.invalidate(allRecipesProvider);

      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message),
            backgroundColor: result.isSavedToCloud
                ? AppColors.forestGreen
                : const Color(0xFF2C5547),
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

    return Scaffold(
      appBar: AppBar(
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
                const SizedBox(height: 24),

                // Title Field
                _buildFieldLabel('Recipe Title', isRequired: true),
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    hintText: 'e.g. Creamy Tuscan Garlic Shrimp',
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
                            decoration: const InputDecoration(),
                            items: AppConstants.categories.map((cat) {
                              return DropdownMenuItem(
                                value: cat,
                                child: Text(cat),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null)
                                setState(() => _selectedCategory = val);
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
                            decoration: const InputDecoration(),
                            items: AppConstants.difficulties.map((diff) {
                              return DropdownMenuItem(
                                value: diff,
                                child: Text(diff),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null)
                                setState(() => _selectedDifficulty = val);
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
                    hintText: 'https://images.unsplash.com/... (or leave blank for preset)',
                  ),
                ),
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
