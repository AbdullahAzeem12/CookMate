import 'package:cook_mate/features/auth/data/repositories/auth_repository.dart';
import 'package:cook_mate/features/auth/domain/services/password_validator.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('PasswordValidator Unit Tests', () {
    test('isValidEmail accurately identifies valid and invalid emails', () {
      expect(PasswordValidator.isValidEmail('chef@cookmate.com'), isTrue);
      expect(PasswordValidator.isValidEmail('gordon.ramsay@kitchen.co.uk'), isTrue);
      expect(PasswordValidator.isValidEmail('invalid-email'), isFalse);
      expect(PasswordValidator.isValidEmail('missing@domain'), isFalse);
      expect(PasswordValidator.isValidEmail(''), isFalse);
    });

    test('calculateStrength returns correct score and tiers', () {
      // Empty
      final empty = PasswordValidator.calculateStrength('');
      expect(empty.tier, PasswordStrengthTier.none);
      expect(empty.score, 0);

      // Weak (< 8 chars)
      final weak = PasswordValidator.calculateStrength('abc');
      expect(weak.score, lessThanOrEqualTo(1));
      expect(weak.hasMinLength, isFalse);

      // Fair (8 chars, lower + number)
      final fair = PasswordValidator.calculateStrength('password1');
      expect(fair.hasMinLength, isTrue);
      expect(fair.hasDigit, isTrue);

      // Strong (8+ chars, upper, lower, number, symbol)
      final strong = PasswordValidator.calculateStrength('ChefMaster123!');
      expect(strong.score, 4);
      expect(strong.tier, PasswordStrengthTier.strong);
      expect(strong.hasMinLength, isTrue);
      expect(strong.hasUpper, isTrue);
      expect(strong.hasLower, isTrue);
      expect(strong.hasDigit, isTrue);
      expect(strong.hasSpecial, isTrue);
    });

    test('doPasswordsMatch checks exact string equality', () {
      expect(PasswordValidator.doPasswordsMatch('secret123', 'secret123'), isTrue);
      expect(PasswordValidator.doPasswordsMatch('secret123', 'secret124'), isFalse);
      expect(PasswordValidator.doPasswordsMatch('', ''), isFalse);
    });
  });

  group('LocalAuthRepository Tests', () {
    late SharedPreferences prefs;
    late LocalAuthRepository authRepo;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      authRepo = LocalAuthRepository(prefs: prefs);
    });

    test('Default seeded chef is available for immediate sign in', () async {
      final user = await authRepo.login(
        email: 'chef@cookmate.com',
        password: 'ChefCook123!',
        rememberMe: true,
      );

      expect(user.email, 'chef@cookmate.com');
      expect(user.name, 'Chef Auguste');
      expect(await authRepo.isRemembered(), isTrue);
      expect(await authRepo.getRememberedEmail(), 'chef@cookmate.com');
    });

    test('Registering a new chef creates account and auto-authenticates', () async {
      final newUser = await authRepo.register(
        name: 'Chef Julia',
        email: 'julia@cuisine.fr',
        password: 'BonAppetit2026!',
      );

      expect(newUser.name, 'Chef Julia');
      expect(newUser.email, 'julia@cuisine.fr');

      final currentUser = await authRepo.getCurrentUser();
      expect(currentUser?.id, newUser.id);
    });

    test('Registering with duplicate email throws AuthException.emailAlreadyInUse', () async {
      await authRepo.register(
        name: 'Chef One',
        email: 'duplicate@cookmate.com',
        password: 'Password123!',
      );

      expect(
        () => authRepo.register(
          name: 'Chef Two',
          email: 'duplicate@cookmate.com',
          password: 'Password123!',
        ),
        throwsA(isA<AuthException>().having((e) => e.code, 'code', 'email_already_in_use')),
      );
    });

    test('Login with unknown email throws AuthException.userNotFound', () async {
      expect(
        () => authRepo.login(
          email: 'unknown@nobody.com',
          password: 'Password123!',
          rememberMe: false,
        ),
        throwsA(isA<AuthException>().having((e) => e.code, 'code', 'user_not_found')),
      );
    });

    test('Login with wrong password throws AuthException.wrongPassword', () async {
      expect(
        () => authRepo.login(
          email: 'chef@cookmate.com',
          password: 'WrongPassword!',
          rememberMe: false,
        ),
        throwsA(isA<AuthException>().having((e) => e.code, 'code', 'wrong_password')),
      );
    });

    test('Remember Me false purges remembered email', () async {
      await authRepo.login(
        email: 'chef@cookmate.com',
        password: 'ChefCook123!',
        rememberMe: false,
      );

      expect(await authRepo.isRemembered(), isFalse);
      expect(await authRepo.getRememberedEmail(), isNull);
    });

    test('Password reset updates password and allows login with new password', () async {
      final success = await authRepo.resetPassword(
        email: 'chef@cookmate.com',
        newPassword: 'BrandNewSecret2026!',
      );
      expect(success, isTrue);

      // Old password fails
      expect(
        () => authRepo.login(
          email: 'chef@cookmate.com',
          password: 'ChefCook123!',
          rememberMe: false,
        ),
        throwsA(isA<AuthException>()),
      );

      // New password succeeds
      final user = await authRepo.login(
        email: 'chef@cookmate.com',
        password: 'BrandNewSecret2026!',
        rememberMe: false,
      );
      expect(user.email, 'chef@cookmate.com');
    });

    test('Logout clears current user session', () async {
      await authRepo.login(
        email: 'chef@cookmate.com',
        password: 'ChefCook123!',
        rememberMe: false,
      );
      expect(await authRepo.getCurrentUser(), isNotNull);

      await authRepo.logout();
      expect(await authRepo.getCurrentUser(), isNull);
    });
  });
}

