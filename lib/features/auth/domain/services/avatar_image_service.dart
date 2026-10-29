import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

/// Portrait beautification and tone filters for Chef profiles.
enum ChefPortraitFilter {
  radiantGlow(
    label: 'Radiant Glow',
    subtitle: 'Smooth skin warmth & bright radiance',
    icon: Icons.auto_awesome_rounded,
    badgeColor: Color(0xFFE67E22),
  ),
  freshVibrant(
    label: 'Fresh & Crisp',
    subtitle: 'High clarity with vivid culinary punch',
    icon: Icons.wb_sunny_rounded,
    badgeColor: Color(0xFF2ECC71),
  ),
  goldenHearth(
    label: 'Golden Hearth',
    subtitle: 'Cozy golden hue & flattering soft tones',
    icon: Icons.local_fire_department_rounded,
    badgeColor: Color(0xFFF39C12),
  ),
  naturalClean(
    label: 'Natural Studio',
    subtitle: 'Balanced lighting & gentle clarity',
    icon: Icons.camera_rounded,
    badgeColor: Color(0xFF3498DB),
  ),
  original(
    label: 'Original',
    subtitle: 'Pure unadjusted center crop',
    icon: Icons.photo_rounded,
    badgeColor: Color(0xFF95A5A6),
  );

  final String label;
  final String subtitle;
  final IconData icon;
  final Color badgeColor;

  const ChefPortraitFilter({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.badgeColor,
  });
}

/// Parameter bundle passed to background isolate via [compute]
/// for zero UI thread blocking during image decoding and filter processing.
class AvatarProcessParams {
  final Uint8List rawBytes;
  final ChefPortraitFilter filter;
  final int targetSize;
  final int quality;

  const AvatarProcessParams({
    required this.rawBytes,
    this.filter = ChefPortraitFilter.radiantGlow,
    this.targetSize = 512,
    this.quality = 90,
  });
}

class AvatarImageService {
  final ImagePicker _picker;

  AvatarImageService({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  /// Prompts the user to capture from camera or pick from gallery,
  /// with camera defaulting to front camera for face portraits.
  /// Downsamples to max 1024x1024 with quality 85 to ensure low-RAM devices
  /// (e.g. Huawei MED-LX9 with 256MB heap) avoid native Dalvik OutOfMemoryError.
  Future<Uint8List?> pickImageBytes({
    required ImageSource source,
    CameraDevice preferredCameraDevice = CameraDevice.front,
    int? maxWidth = 1024,
    int? maxHeight = 1024,
    int? imageQuality = 85,
  }) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        preferredCameraDevice: preferredCameraDevice,
        maxWidth: maxWidth?.toDouble(),
        maxHeight: maxHeight?.toDouble(),
        imageQuality: imageQuality,
      );

      if (pickedFile == null) return null;
      return await pickedFile.readAsBytes();
    } catch (e) {
      debugPrint('Error picking image: $e');
      return null;
    }
  }

  /// Recovers the selected photo when Android kills MainActivity in the background
  /// while external gallery or camera applications were running in the foreground.
  Future<Uint8List?> retrieveLostData() async {
    try {
      final LostDataResponse response = await _picker.retrieveLostData();
      if (response.isEmpty) return null;
      final file = response.file ??
          (response.files != null && response.files!.isNotEmpty
              ? response.files!.first
              : null);
      if (file != null) {
        return await file.readAsBytes();
      }
    } catch (e) {
      debugPrint('Error retrieving lost image data: $e');
    }
    return null;
  }

  /// Top-level/static worker function executed in an isolated background thread.
  static Uint8List _isolateProcessWorker(AvatarProcessParams params) {
    return processAndBeautify(
      rawBytes: params.rawBytes,
      filter: params.filter,
      targetSize: params.targetSize,
      quality: params.quality,
    );
  }

  /// Runs [processAndBeautify] asynchronously in a background Dart isolate using [compute],
  /// guaranteeing the main UI thread never drops frames or triggers Android ANR watchdogs.
  static Future<Uint8List> processAndBeautifyAsync({
    required Uint8List rawBytes,
    ChefPortraitFilter filter = ChefPortraitFilter.radiantGlow,
    int targetSize = 512,
    int quality = 90,
  }) {
    return compute(
      _isolateProcessWorker,
      AvatarProcessParams(
        rawBytes: rawBytes,
        filter: filter,
        targetSize: targetSize,
        quality: quality,
      ),
    );
  }

  /// Automatically center-crops to 1:1 square, resizes to [targetSize],
  /// and applies the selected face-enhancing beauty filter.
  static Uint8List processAndBeautify({
    required Uint8List rawBytes,
    ChefPortraitFilter filter = ChefPortraitFilter.radiantGlow,
    int targetSize = 512,
    int quality = 90,
  }) {
    final image = img.decodeImage(rawBytes);
    if (image == null) {
      throw Exception('Unable to process selected image file.');
    }

    // 1. Auto square center-crop
    final cropSize = math.min(image.width, image.height);
    final cropX = (image.width - cropSize) ~/ 2;
    final cropY = (image.height - cropSize) ~/ 2;

    var processed = img.copyCrop(
      image,
      x: cropX,
      y: cropY,
      width: cropSize,
      height: cropSize,
    );

    // 2. Resize to high quality profile dimension (512x512)
    if (processed.width != targetSize) {
      processed = img.copyResize(
        processed,
        width: targetSize,
        height: targetSize,
        interpolation: img.Interpolation.linear,
      );
    }

    // 3. Apply beauty and face-prettifying filter curves
    switch (filter) {
      case ChefPortraitFilter.radiantGlow:
        // Gentle warm boost, lifted shadows, healthy skin tone
        processed = img.adjustColor(
          processed,
          brightness: 1.06,
          contrast: 1.08,
          saturation: 1.08,
          gamma: 0.96,
        );
        break;
      case ChefPortraitFilter.freshVibrant:
        // Crisp clarity, boosted vibrancy for expressive portraits
        processed = img.adjustColor(
          processed,
          brightness: 1.08,
          contrast: 1.12,
          saturation: 1.14,
        );
        break;
      case ChefPortraitFilter.goldenHearth:
        // Warm amber culinary tone
        processed = img.adjustColor(
          processed,
          brightness: 1.05,
          contrast: 1.06,
          saturation: 1.10,
        );
        break;
      case ChefPortraitFilter.naturalClean:
        // Minimal enhancement, studio clean
        processed = img.adjustColor(
          processed,
          brightness: 1.03,
          contrast: 1.05,
          saturation: 1.03,
        );
        break;
      case ChefPortraitFilter.original:
        // No filter applied
        break;
    }

    return Uint8List.fromList(img.encodeJpg(processed, quality: quality));
  }

  /// Persists the processed image into local app storage
  /// (`chef_avatars/avatar_<userId>_<timestamp>.jpg`) and deletes old avatar files.
  static Future<String> saveAvatarLocally({
    required Uint8List bytes,
    required String userId,
    Directory? customBaseDir,
  }) async {
    final baseDir = customBaseDir ?? await getApplicationDocumentsDirectory();
    final avatarsDir = Directory('${baseDir.path}/chef_avatars');
    if (!await avatarsDir.exists()) {
      await avatarsDir.create(recursive: true);
    }

    // Clean up older avatars for this user
    try {
      final existingFiles = avatarsDir.listSync();
      for (final entity in existingFiles) {
        if (entity is File && entity.path.contains('avatar_${userId}_')) {
          entity.deleteSync();
        }
      }
    } catch (_) {
      // Ignore cleanup error
    }

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final filePath = '${avatarsDir.path}/avatar_${userId}_$timestamp.jpg';
    final file = File(filePath);
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  /// Deletes a local avatar file if it exists.
  static Future<void> deleteLocalAvatar(String? path) async {
    if (path == null || path.isEmpty) return;
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {}
  }
}

