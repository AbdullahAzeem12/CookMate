class Recipe {
  final String id;
  final String title;
  final String description;
  final String category;
  final String imageUrl;
  final List<String> ingredients;
  final List<String> instructions;
  final int prepMinutes;
  final int cookMinutes;
  final int servings;
  final String difficulty;
  final List<String> tags;
  final DateTime? createdAt;
  final bool isCommunitySubmission;
  final String? authorUid;
  final String status;

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
    this.createdAt,
    this.isCommunitySubmission = false,
    this.authorUid,
    this.status = 'approved',
  });

  /// Derived total cooking time
  int get totalMinutes => prepMinutes + cookMinutes;

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
          [],
      instructions:
          (json['instructions'] as List<dynamic>?)
              ?.map((e) => e.toString().trim())
              .where((s) => s.isNotEmpty)
              .toList() ??
          [],
      prepMinutes: (json['prepMinutes'] as num?)?.toInt() ?? 0,
      cookMinutes: (json['cookMinutes'] as num?)?.toInt() ?? 0,
      servings: (json['servings'] as num?)?.toInt() ?? 1,
      difficulty: json['difficulty'] as String? ?? 'Easy',
      tags:
          (json['tags'] as List<dynamic>?)
              ?.map((e) => e.toString().trim())
              .where((s) => s.isNotEmpty)
              .toList() ??
          [],
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
      isCommunitySubmission: json['isCommunitySubmission'] as bool? ?? false,
      authorUid: json['authorUid'] as String?,
      status: json['status'] as String? ?? 'approved',
    );
  }

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
      'createdAt': createdAt?.toIso8601String(),
      'isCommunitySubmission': isCommunitySubmission,
      'authorUid': authorUid,
      'status': status,
    };
  }

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
    DateTime? createdAt,
    bool? isCommunitySubmission,
    String? authorUid,
    String? status,
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
      createdAt: createdAt ?? this.createdAt,
      isCommunitySubmission:
          isCommunitySubmission ?? this.isCommunitySubmission,
      authorUid: authorUid ?? this.authorUid,
      status: status ?? this.status,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Recipe && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
