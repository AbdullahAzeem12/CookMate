class UserProfile {
  final String id;
  final String name;
  final String email;
  final String passwordHash;
  final String? avatarUrl;
  final DateTime joinedAt;
  final List<String> dietaryPreferences;
  final String skillLevel;
  final String? bio;

  const UserProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.passwordHash,
    this.avatarUrl,
    required this.joinedAt,
    this.dietaryPreferences = const [],
    this.skillLevel = 'Home Chef',
    this.bio,
  });

  UserProfile copyWith({
    String? id,
    String? name,
    String? email,
    String? passwordHash,
    String? avatarUrl,
    DateTime? joinedAt,
    List<String>? dietaryPreferences,
    String? skillLevel,
    String? bio,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      passwordHash: passwordHash ?? this.passwordHash,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      joinedAt: joinedAt ?? this.joinedAt,
      dietaryPreferences: dietaryPreferences ?? this.dietaryPreferences,
      skillLevel: skillLevel ?? this.skillLevel,
      bio: bio ?? this.bio,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'passwordHash': passwordHash,
      'avatarUrl': avatarUrl,
      'joinedAt': joinedAt.toIso8601String(),
      'dietaryPreferences': dietaryPreferences,
      'skillLevel': skillLevel,
      'bio': bio,
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      passwordHash: json['passwordHash'] as String,
      avatarUrl: json['avatarUrl'] as String?,
      joinedAt: json['joinedAt'] != null
          ? DateTime.parse(json['joinedAt'] as String)
          : DateTime.now(),
      dietaryPreferences: json['dietaryPreferences'] != null
          ? List<String>.from(json['dietaryPreferences'] as List)
          : const [],
      skillLevel: json['skillLevel'] as String? ?? 'Home Chef',
      bio: json['bio'] as String?,
    );
  }
}

