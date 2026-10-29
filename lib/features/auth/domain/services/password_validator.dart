import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

enum PasswordStrengthTier {
  none,
  weak,
  fair,
  good,
  strong,
}

class PasswordStrengthResult {
  final int score; // 0 to 4
  final PasswordStrengthTier tier;
  final String label;
  final Color color;
  final bool hasMinLength;
  final bool hasUpper;
  final bool hasLower;
  final bool hasDigit;
  final bool hasSpecial;

  const PasswordStrengthResult({
    required this.score,
    required this.tier,
    required this.label,
    required this.color,
    required this.hasMinLength,
    required this.hasUpper,
    required this.hasLower,
    required this.hasDigit,
    required this.hasSpecial,
  });

  bool get isAcceptable => score >= 3;
}

class PasswordValidator {
  const PasswordValidator._();

  static final RegExp _emailRegex = RegExp(
    r'^[a-zA-Z0-9.!#$%&’*+/=?^_`{|}~-]+@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)+$',
  );

  static final RegExp _upperRegex = RegExp(r'[A-Z]');
  static final RegExp _lowerRegex = RegExp(r'[a-z]');
  static final RegExp _digitRegex = RegExp(r'[0-9]');
  static final RegExp _specialRegex = RegExp(r'[!@#\$%^&*(),.?":{}|<>_\-+=~`[\]\\\/]');

  /// Validates whether the given string is a valid email format.
  static bool isValidEmail(String email) {
    if (email.trim().isEmpty) return false;
    return _emailRegex.hasMatch(email.trim());
  }

  /// Evaluates password strength based on length, complexity, and character sets.
  static PasswordStrengthResult calculateStrength(String password) {
    if (password.isEmpty) {
      return const PasswordStrengthResult(
        score: 0,
        tier: PasswordStrengthTier.none,
        label: 'Enter password',
        color: Colors.grey,
        hasMinLength: false,
        hasUpper: false,
        hasLower: false,
        hasDigit: false,
        hasSpecial: false,
      );
    }

    final hasMinLength = password.length >= 8;
    final hasUpper = _upperRegex.hasMatch(password);
    final hasLower = _lowerRegex.hasMatch(password);
    final hasDigit = _digitRegex.hasMatch(password);
    final hasSpecial = _specialRegex.hasMatch(password);

    int count = 0;
    if (hasMinLength) count++;
    if (hasUpper && hasLower) count++;
    if (hasDigit) count++;
    if (hasSpecial) count++;

    // Extra length bonus (12+ characters) boosts score if already meeting basic rules
    if (password.length >= 12 && count >= 3) {
      count = 4;
    }

    switch (count) {
      case 1:
        return PasswordStrengthResult(
          score: 1,
          tier: PasswordStrengthTier.weak,
          label: 'Weak',
          color: AppColors.softCoral,
          hasMinLength: hasMinLength,
          hasUpper: hasUpper,
          hasLower: hasLower,
          hasDigit: hasDigit,
          hasSpecial: hasSpecial,
        );
      case 2:
        return PasswordStrengthResult(
          score: 2,
          tier: PasswordStrengthTier.fair,
          label: 'Fair',
          color: AppColors.goldenAmber,
          hasMinLength: hasMinLength,
          hasUpper: hasUpper,
          hasLower: hasLower,
          hasDigit: hasDigit,
          hasSpecial: hasSpecial,
        );
      case 3:
        return PasswordStrengthResult(
          score: 3,
          tier: PasswordStrengthTier.good,
          label: 'Good',
          color: AppColors.citrusLime,
          hasMinLength: hasMinLength,
          hasUpper: hasUpper,
          hasLower: hasLower,
          hasDigit: hasDigit,
          hasSpecial: hasSpecial,
        );
      case 4:
        return PasswordStrengthResult(
          score: 4,
          tier: PasswordStrengthTier.strong,
          label: 'Strong & Secure',
          color: const Color(0xFF2ECC71),
          hasMinLength: hasMinLength,
          hasUpper: hasUpper,
          hasLower: hasLower,
          hasDigit: hasDigit,
          hasSpecial: hasSpecial,
        );
      default:
        return PasswordStrengthResult(
          score: 0,
          tier: PasswordStrengthTier.weak,
          label: 'Too Short',
          color: AppColors.softCoral,
          hasMinLength: hasMinLength,
          hasUpper: hasUpper,
          hasLower: hasLower,
          hasDigit: hasDigit,
          hasSpecial: hasSpecial,
        );
    }
  }

  /// Compares password and confirmation password.
  static bool doPasswordsMatch(String password, String confirmPassword) {
    if (password.isEmpty || confirmPassword.isEmpty) return false;
    return password == confirmPassword;
  }
}

