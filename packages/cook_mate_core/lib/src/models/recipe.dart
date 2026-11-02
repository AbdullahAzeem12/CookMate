/// Core immutable entity representing a culinary recipe.
class Recipe {
  /// Unique identifier of the recipe.
  final String id;

  /// Title or name of the dish.
  final String title;

  /// Brief editorial description or culinary background.
  final String description;

  /// Primary category (e.g., Quick & Easy, Healthy Meals, Desserts).
  final String category;

  /// High-resolution image URL.
  final String imageUrl;

  /// Ordered list of raw or formatted ingredient strings.
  final List<String> ingredients;

  /// Ordered list of preparation and cooking instructions.
  final List<String> instructions;

  /// Estimated preparation time in minutes.
  final int prepMinutes;

  /// Estimated cooking time in minutes.
  final int cookMinutes;

  /// Base number of servings this recipe yields.
  final int servings;

  /// Skill level required (e.g., Easy, Medium, Hard).
  final String difficulty;

  /// Descriptive search tags, cuisines, and diet labels.
  final List<String> tags;

  /// Optional tips, pairings, or chef notes.
  final String? chefNotes;

  /// Timestamp when the recipe was created or published.
  final DateTime? createdAt;

  /// Whether this recipe was submitted by an external community chef.
  final bool isCommunitySubmission;

  /// User identifier of the author if community-submitted.
  final String? authorUid;

  /// Approval status (e.g., 'approved', 'pending', 'draft').
  final String status;

  /// Whether this recipe is highlighted in featured card decks.
  final bool isChefsPick;

  const Recipe({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.imageUrl,
    required this.ingredients,
    required this.instructions,
    required this.prepMinutes,
    required this.cookMinutes,
    required this.servings,
    required this.difficulty,
    required this.tags,
    this.chefNotes,
    this.createdAt,
    this.isCommunitySubmission = false,
    this.authorUid,
    this.status = 'approved',
    this.isChefsPick = false,
  });

  /// Derived total cooking time in minutes.
  int get totalMinutes => prepMinutes + cookMinutes;

  /// Deserializes a [Map] into a [Recipe] with resilient null-safety fallbacks.
  factory Recipe.fromJson(Map<String, dynamic> json) {
    return Recipe(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? 'Untitled Recipe',
      description: json['description'] as String? ?? '',
      category: json['category'] as String? ?? 'Quick & Easy',
      imageUrl: json['imageUrl'] as String? ?? '',
      ingredients:
          (json['ingredients'] as List<dynamic>?)
              ?.map((e) => e.toString().trim())
              .where((s) => s.isNotEmpty)
              .toList() ??
          const [],
      instructions:
          (json['instructions'] as List<dynamic>?)
              ?.map((e) => e.toString().trim())
              .where((s) => s.isNotEmpty)
              .toList() ??
          const [],
      prepMinutes: (json['prepMinutes'] as num?)?.toInt() ?? 0,
      cookMinutes: (json['cookMinutes'] as num?)?.toInt() ?? 0,
      servings: (json['servings'] as num?)?.toInt() ?? 1,
      difficulty: json['difficulty'] as String? ?? 'Easy',
      tags:
          (json['tags'] as List<dynamic>?)
              ?.map((e) => e.toString().trim())
              .where((s) => s.isNotEmpty)
              .toList() ??
          const [],
      chefNotes: json['chefNotes'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
      isCommunitySubmission: json['isCommunitySubmission'] as bool? ?? false,
      authorUid: json['authorUid'] as String?,
      status: json['status'] as String? ?? 'approved',
      isChefsPick: json['isChefsPick'] as bool? ?? false,
    );
  }

  /// Serializes this [Recipe] into a standard JSON-compatible map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'imageUrl': imageUrl,
      'ingredients': ingredients,
      'instructions': instructions,
      'prepMinutes': prepMinutes,
      'cookMinutes': cookMinutes,
      'servings': servings,
      'difficulty': difficulty,
      'tags': tags,
      'chefNotes': chefNotes,
      'createdAt': createdAt?.toIso8601String(),
      'isCommunitySubmission': isCommunitySubmission,
      'authorUid': authorUid,
      'status': status,
      'isChefsPick': isChefsPick,
    };
  }

  /// Returns a copy of this [Recipe] with specified fields replaced.
  Recipe copyWith({
    String? id,
    String? title,
    String? description,
    String? category,
    String? imageUrl,
    List<String>? ingredients,
    List<String>? instructions,
    int? prepMinutes,
    int? cookMinutes,
    int? servings,
    String? difficulty,
    List<String>? tags,
    String? chefNotes,
    DateTime? createdAt,
    bool? isCommunitySubmission,
    String? authorUid,
    String? status,
    bool? isChefsPick,
  }) {
    return Recipe(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      imageUrl: imageUrl ?? this.imageUrl,
      ingredients: ingredients ?? this.ingredients,
      instructions: instructions ?? this.instructions,
      prepMinutes: prepMinutes ?? this.prepMinutes,
      cookMinutes: cookMinutes ?? this.cookMinutes,
      servings: servings ?? this.servings,
      difficulty: difficulty ?? this.difficulty,
      tags: tags ?? this.tags,
      chefNotes: chefNotes ?? this.chefNotes,
      createdAt: createdAt ?? this.createdAt,
      isCommunitySubmission:
          isCommunitySubmission ?? this.isCommunitySubmission,
      authorUid: authorUid ?? this.authorUid,
      status: status ?? this.status,
      isChefsPick: isChefsPick ?? this.isChefsPick,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Recipe &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title;

  @override
  int get hashCode => id.hashCode ^ title.hashCode;

  @override
  String toString() => 'Recipe(id: "$id", title: "$title", servings: $servings)';
}
