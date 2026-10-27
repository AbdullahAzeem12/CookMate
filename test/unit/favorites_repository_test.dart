import 'package:cook_mate/features/favorites/data/favorites_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FavoritesRepository Tests', () {
    late LocalFavoritesRepository repository;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      repository = LocalFavoritesRepository();
    });

    test('Initial favorite IDs set is empty', () async {
      final ids = await repository.getFavoriteIds();
      expect(ids, isEmpty);
    });

    test('Adding favorite persists ID and prevents duplicates', () async {
      await repository.addFavorite('classic-pasta');
      await repository.addFavorite('classic-pasta'); // duplicate attempt

      final ids = await repository.getFavoriteIds();
      expect(ids.length, 1);
      expect(ids.contains('classic-pasta'), isTrue);
    });

    test('Removing favorite deletes ID correctly', () async {
      await repository.addFavorite('classic-pasta');
      await repository.addFavorite('quinoa-salad');

      await repository.removeFavorite('classic-pasta');

      final ids = await repository.getFavoriteIds();
      expect(ids.length, 1);
      expect(ids.contains('classic-pasta'), isFalse);
      expect(ids.contains('quinoa-salad'), isTrue);
    });

    test('clearFavorites purges all saved items', () async {
      await repository.addFavorite('classic-pasta');
      await repository.addFavorite('quinoa-salad');

      await repository.clearFavorites();

      final ids = await repository.getFavoriteIds();
      expect(ids, isEmpty);
    });
  });
}
