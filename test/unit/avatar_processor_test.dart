import 'dart:typed_data';
import 'package:cook_mate/features/auth/domain/services/avatar_image_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AvatarImageService & Beautification Tests', () {
    late Uint8List sampleBytes;

    setUp(() {
      final imgObj = img.Image(width: 800, height: 600);
      img.fill(imgObj, color: img.ColorRgb8(210, 160, 130)); // Skin-like tone
      sampleBytes = Uint8List.fromList(img.encodeJpg(imgObj));
    });

    test('Auto center-crops non-square rectangular image into exact square', () {
      final resultBytes = AvatarImageService.processAndBeautify(
        rawBytes: sampleBytes,
        targetSize: 256,
        filter: ChefPortraitFilter.original,
      );

      final decoded = img.decodeImage(resultBytes);
      expect(decoded, isNotNull);
      expect(decoded?.width, 256);
      expect(decoded?.height, 256);
    });

    test('Applies Radiant Glow beauty filter and returns valid JPEG', () {
      final resultBytes = AvatarImageService.processAndBeautify(
        rawBytes: sampleBytes,
        targetSize: 128,
        filter: ChefPortraitFilter.radiantGlow,
      );

      final decoded = img.decodeImage(resultBytes);
      expect(decoded, isNotNull);
      expect(decoded?.width, 128);
      expect(decoded?.height, 128);
    });

    test('All beauty filters successfully execute and produce valid output', () {
      for (final filter in ChefPortraitFilter.values) {
        final resultBytes = AvatarImageService.processAndBeautify(
          rawBytes: sampleBytes,
          targetSize: 100,
          filter: filter,
        );
        final decoded = img.decodeImage(resultBytes);
        expect(decoded, isNotNull);
        expect(decoded?.width, 100);
        expect(decoded?.height, 100);
      }
    });

    test('processAndBeautifyAsync executes in background worker and returns valid processed portrait', () async {
      final resultBytes = await AvatarImageService.processAndBeautifyAsync(
        rawBytes: sampleBytes,
        targetSize: 200,
        filter: ChefPortraitFilter.freshVibrant,
      );

      final decoded = img.decodeImage(resultBytes);
      expect(decoded, isNotNull);
      expect(decoded?.width, 200);
      expect(decoded?.height, 200);
    });

    test('retrieveLostData returns null safely when no pending intent result exists', () async {
      final service = AvatarImageService();
      final lostData = await service.retrieveLostData();
      expect(lostData, isNull);
    });
  });
}
