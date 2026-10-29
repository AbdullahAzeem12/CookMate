import 'dart:typed_data';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/bounce_tap.dart';
import '../../domain/services/avatar_image_service.dart';

/// Interactive modal dialog allowing chefs to preview their auto-cropped portrait,
/// select a face-prettifying beauty filter, and confirm profile upload.
class AvatarPreviewDialog extends StatefulWidget {
  final Uint8List rawBytes;

  const AvatarPreviewDialog({
    super.key,
    required this.rawBytes,
  });

  static Future<Uint8List?> show(BuildContext context, Uint8List rawBytes) {
    return showDialog<Uint8List?>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AvatarPreviewDialog(rawBytes: rawBytes),
    );
  }

  @override
  State<AvatarPreviewDialog> createState() => _AvatarPreviewDialogState();
}

class _AvatarPreviewDialogState extends State<AvatarPreviewDialog>
    with SingleTickerProviderStateMixin {
  late ChefPortraitFilter _selectedFilter;
  Uint8List? _processedBytes;
  bool _isProcessing = false;
  int _filterOpId = 0;
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _selectedFilter = ChefPortraitFilter.radiantGlow;
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _applyFilter(_selectedFilter);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _applyFilter(ChefPortraitFilter filter) async {
    final currentOp = ++_filterOpId;
    setState(() {
      _selectedFilter = filter;
      _isProcessing = true;
    });

    try {
      final processed = await AvatarImageService.processAndBeautifyAsync(
        rawBytes: widget.rawBytes,
        filter: filter,
        targetSize: 512,
        quality: 90,
      );
      if (mounted && currentOp == _filterOpId) {
        setState(() {
          _processedBytes = processed;
          _isProcessing = false;
        });
      }
    } catch (e) {
      if (mounted && currentOp == _filterOpId) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      backgroundColor: isDark ? const Color(0xFF132821) : Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.citrusLime.withValues(alpha: 0.18),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.face_retouching_natural_rounded,
                          color: AppColors.goldenAmber,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Chef Portrait Studio',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.of(context).pop(null),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Auto-cropped & centered. Select a beauty tone to enhance your portrait.',
                style: TextStyle(
                  fontSize: 12.5,
                  color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                ),
              ),
              const SizedBox(height: 20),

              // Circular Avatar Preview with Animated Glow
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  final glowRadius = 14.0 + (_pulseController.value * 10.0);
                  return Container(
                    width: 176,
                    height: 176,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(38),
                      boxShadow: [
                        BoxShadow(
                          color: _selectedFilter.badgeColor.withValues(alpha: 0.35),
                          blurRadius: glowRadius,
                          spreadRadius: 2,
                        ),
                      ],
                      border: Border.all(
                        color: isDark ? AppColors.citrusLime : AppColors.forestGreen,
                        width: 3,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(34),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          if (_processedBytes != null)
                            Image.memory(
                              _processedBytes!,
                              fit: BoxFit.cover,
                            )
                          else
                            const Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.citrusLime,
                              ),
                            ),
                          if (_isProcessing)
                            Container(
                              color: Colors.black38,
                              child: const Center(
                                child: SizedBox(
                                  width: 28,
                                  height: 28,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),

              // Filter Tag
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: _selectedFilter.badgeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _selectedFilter.badgeColor.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _selectedFilter.icon,
                      size: 14,
                      color: _selectedFilter.badgeColor,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      _selectedFilter.subtitle,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: _selectedFilter.badgeColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Filter Selector List
              SizedBox(
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: ChefPortraitFilter.values.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final filter = ChefPortraitFilter.values[index];
                    final isSelected = filter == _selectedFilter;

                    return BounceTap(
                      onTap: () => _applyFilter(filter),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? (isDark ? AppColors.citrusLime : AppColors.forestGreen)
                              : (isDark
                                  ? Colors.white.withValues(alpha: 0.08)
                                  : Colors.black.withValues(alpha: 0.05)),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.citrusLime
                                : (isDark
                                    ? Colors.white.withValues(alpha: 0.15)
                                    : Colors.black.withValues(alpha: 0.10)),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              filter.icon,
                              size: 15,
                              color: isSelected
                                  ? (isDark ? AppColors.deepEmerald : Colors.white)
                                  : (isDark ? AppColors.textLight : AppColors.textDark),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              filter.label,
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight:
                                    isSelected ? FontWeight.w800 : FontWeight.w600,
                                color: isSelected
                                    ? (isDark ? AppColors.deepEmerald : Colors.white)
                                    : (isDark ? AppColors.textLight : AppColors.textDark),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 22),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        side: BorderSide(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.2)
                              : Colors.black.withValues(alpha: 0.15),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                      ),
                      onPressed: () => Navigator.of(context).pop(null),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: BounceTap(
                      onTap: _processedBytes == null || _isProcessing
                          ? null
                          : () => Navigator.of(context).pop(_processedBytes),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.forestGreen.withValues(alpha: 0.35),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.check_circle_rounded,
                                color: AppColors.citrusLime,
                                size: 18,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'Apply to Profile',
                                style: TextStyle(
                                  color: AppColors.citrusLime,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

