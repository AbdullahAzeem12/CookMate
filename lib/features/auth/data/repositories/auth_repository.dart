import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../domain/models/user_profile.dart';
import '../../domain/services/password_validator.dart';

class AuthException implements Exception {
  final String message;
  final String code;

  const AuthException(this.message, {this.code = 'auth_error'});

  factory AuthException.userNotFound() => const AuthException(
        'No chef account found with this email address. Please sign up first.',
        code: 'user_not_found',
      );

  factory AuthException.wrongPassword() => const AuthException(
        'Incorrect password. Please verify your credentials or tap "Forgot Password".',
        code: 'wrong_password',
      );

  factory AuthException.emailAlreadyInUse() => const AuthException(
        'An account with this email is already registered. Please sign in instead.',
        code: 'email_already_in_use',
      );

  factory AuthException.invalidEmail() => const AuthException(
        'Please enter a valid email address (e.g., chef@cookmate.com).',
        code: 'invalid_email',
      );

  factory AuthException.weakPassword() => const AuthException(
        'Password does not meet security requirements. Please use at least 8 characters with numbers or symbols.',
        code: 'weak_password',
      );

  factory AuthException.passwordsDoNotMatch() => const AuthException(
        'Password confirmation does not match the chosen password.',
        code: 'password_mismatch',
      );

  @override
  String toString() => message;
}

abstract interface class AuthRepository {
  Future<UserProfile?> getCurrentUser();
  Future<UserProfile> register({
    required String name,
    required String email,
    required String password,
  });
  Future<UserProfile> login({
    required String email,
    required String password,
    required bool rememberMe,
  });
  Future<void> logout();
  Future<bool> resetPassword({
    required String email,
    required String newPassword,
  });
  Future<String?> getRememberedEmail();
  Future<bool> isRemembered();
  Future<void> updateProfile(UserProfile updated);
}

class LocalAuthRepository implements AuthRepository {
  static const String _usersKey = 'cookmate_registered_users';
  static const String _activeSessionKey = 'cookmate_active_user_id';
  static const String _rememberMeKey = 'cookmate_remember_me_flag';
  static const String _rememberedEmailKey = 'cookmate_remembered_email';

  final SharedPreferences? _prefsOverride;
  final Uuid _uuid;

  List<UserProfile>? _cachedUsers;
  UserProfile? _cachedCurrentUser;

  LocalAuthRepository({SharedPreferences? prefs})
      : _prefsOverride = prefs,
        _uuid = const Uuid();

  Future<SharedPreferences> get _prefs async =>
      _prefsOverride ?? await SharedPreferences.getInstance();

  Future<List<UserProfile>> _loadUsers() async {
    if (_cachedUsers != null) return _cachedUsers!;

    final prefs = await _prefs;
    final jsonString = prefs.getString(_usersKey);

    if (jsonString != null && jsonString.isNotEmpty) {
      try {
        final decoded = json.decode(jsonString) as List;
        _cachedUsers = decoded
            .map((item) => UserProfile.fromJson(item as Map<String, dynamic>))
            .toList();
      } catch (_) {
        _cachedUsers = [];
      }
    } else {
      // Seed default chef user for out-of-the-box convenience
      _cachedUsers = [
        UserProfile(
          id: 'default-chef-1',
          name: 'Chef Auguste',
          email: 'chef@cookmate.com',
          passwordHash: _hashPassword('ChefCook123!'),
          avatarUrl: 'https://images.unsplash.com/photo-1577219491135-ce391730fb2c',
          joinedAt: DateTime(2026, 1, 1),
          dietaryPreferences: ['Mediterranean', 'Healthy Eating'],
          skillLevel: 'Master Chef',
          bio: 'Passionate culinary artist crafting flavors from farm to table.',
        ),
      ];
      await _saveUsers(_cachedUsers!);
    }

    return _cachedUsers!;
  }

  Future<void> _saveUsers(List<UserProfile> users) async {
    final prefs = await _prefs;
    final encoded = json.encode(users.map((u) => u.toJson()).toList());
    await prefs.setString(_usersKey, encoded);
    _cachedUsers = users;
  }

  String _hashPassword(String raw) {
    // Basic reversible secure hash representation for offline demonstration
    final bytes = utf8.encode('salt_cookmate_$raw');
    return base64.encode(bytes);
  }

  @override
  Future<UserProfile?> getCurrentUser() async {
    if (_cachedCurrentUser != null) return _cachedCurrentUser;

    final prefs = await _prefs;
    final activeId = prefs.getString(_activeSessionKey);
    if (activeId == null) return null;

    final users = await _loadUsers();
    try {
      _cachedCurrentUser = users.firstWhere((u) => u.id == activeId);
      return _cachedCurrentUser;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<UserProfile> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    final cleanName = name.trim();

    if (!PasswordValidator.isValidEmail(cleanEmail)) {
      throw AuthException.invalidEmail();
    }

    final strength = PasswordValidator.calculateStrength(password);
    if (strength.score < 2) {
      throw AuthException.weakPassword();
    }

    final users = await _loadUsers();
    final alreadyExists = users.any(
      (u) => u.email.toLowerCase() == cleanEmail,
    );
    if (alreadyExists) {
      throw AuthException.emailAlreadyInUse();
    }

    final newUser = UserProfile(
      id: _uuid.v4(),
      name: cleanName.isNotEmpty ? cleanName : 'Chef ${cleanEmail.split('@').first}',
      email: cleanEmail,
      passwordHash: _hashPassword(password),
      joinedAt: DateTime.now(),
      dietaryPreferences: const ['All Cuisines'],
      skillLevel: 'Home Chef',
      bio: 'Ready to discover culinary wonders with CookMate!',
    );

    users.add(newUser);
    await _saveUsers(users);

    // Auto-login registered user
    final prefs = await _prefs;
    await prefs.setString(_activeSessionKey, newUser.id);
    _cachedCurrentUser = newUser;

    return newUser;
  }

  @override
  Future<UserProfile> login({
    required String email,
    required String password,
    required bool rememberMe,
  }) async {
    final cleanEmail = email.trim().toLowerCase();

    if (!PasswordValidator.isValidEmail(cleanEmail)) {
      throw AuthException.invalidEmail();
    }

    final users = await _loadUsers();
    final matchingUser = users.cast<UserProfile?>().firstWhere(
          (u) => u?.email.toLowerCase() == cleanEmail,
          orElse: () => null,
        );

    if (matchingUser == null) {
      throw AuthException.userNotFound();
    }

    final expectedHash = _hashPassword(password);
    if (matchingUser.passwordHash != expectedHash) {
      throw AuthException.wrongPassword();
    }

    final prefs = await _prefs;
    await prefs.setString(_activeSessionKey, matchingUser.id);
    await prefs.setBool(_rememberMeKey, rememberMe);

    if (rememberMe) {
      await prefs.setString(_rememberedEmailKey, cleanEmail);
    } else {
      await prefs.remove(_rememberedEmailKey);
    }

    _cachedCurrentUser = matchingUser;
    return matchingUser;
  }

  @override
  Future<void> logout() async {
    final prefs = await _prefs;
    await prefs.remove(_activeSessionKey);
    _cachedCurrentUser = null;
  }

  @override
  Future<bool> resetPassword({
    required String email,
    required String newPassword,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    final users = await _loadUsers();

    final userIndex = users.indexWhere(
      (u) => u.email.toLowerCase() == cleanEmail,
    );
    if (userIndex == -1) {
      throw AuthException.userNotFound();
    }

    final strength = PasswordValidator.calculateStrength(newPassword);
    if (strength.score < 2) {
      throw AuthException.weakPassword();
    }

    final updated = users[userIndex].copyWith(
      passwordHash: _hashPassword(newPassword),
    );
    users[userIndex] = updated;
    await _saveUsers(users);

    if (_cachedCurrentUser?.id == updated.id) {
      _cachedCurrentUser = updated;
    }

    return true;
  }

  @override
  Future<String?> getRememberedEmail() async {
    final prefs = await _prefs;
    final isRem = prefs.getBool(_rememberMeKey) ?? false;
    if (!isRem) return null;
    return prefs.getString(_rememberedEmailKey);
  }

  @override
  Future<bool> isRemembered() async {
    final prefs = await _prefs;
    return prefs.getBool(_rememberMeKey) ?? false;
  }

  @override
  Future<void> updateProfile(UserProfile updated) async {
    final users = await _loadUsers();
    final index = users.indexWhere((u) => u.id == updated.id);
    if (index != -1) {
      users[index] = updated;
      await _saveUsers(users);
      _cachedCurrentUser = updated;
    }
  }
}

