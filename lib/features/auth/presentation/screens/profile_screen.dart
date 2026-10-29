import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_cached_network_image.dart';
import '../../../../shared/widgets/app_logo_badge.dart';
import '../../../../shared/widgets/bounce_tap.dart';
import '../../../favorites/presentation/providers/favorites_providers.dart';
import '../../../recipes/domain/models/recipe.dart';
import '../../../recipes/presentation/providers/recipe_providers.dart';
import '../../domain/models/user_profile.dart';
import '../../domain/services/avatar_image_service.dart';
import '../providers/auth_providers.dart';
import '../widgets/avatar_preview_dialog.dart';
import '../widgets/avatar_source_sheet.dart';
import '../widgets/chef_avatar_view.dart';
import '../widgets/shiny_glass_card.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkRecoveredAvatar();
    });
  }

  /// Checks for any image recovered after an Android activity recreation,
  /// either from global pending provider or direct picker retrieval.
  Future<void> _checkRecoveredAvatar() async {
    if (!mounted) return;
    Uint8List? rawBytes = ref.read(pendingAvatarBytesProvider);
    if (rawBytes != null) {
      ref.read(pendingAvatarBytesProvider.notifier).state = null;
    } else {
      final pickerService = ref.read(avatarImageServiceProvider);
      rawBytes = await pickerService.retrieveLostData();
    }

    if (rawBytes != null && mounted) {
      final user = ref.read(currentUserProvider);
      if (user != null) {
        await _processAndSaveAvatar(rawBytes, user);
      }
    }
  }

  void _showSignOutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out of CookMate?'),
        content: const Text(
          'Are you sure you want to sign out? Your saved offline data will remain preserved on this device.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.softCoral,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(authNotifierProvider.notifier).logout();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Successfully signed out of CookMate.'),
                    backgroundColor: AppColors.forestGreen,
                  ),
                );
              }
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  Future<void> _processAndSaveAvatar(Uint8List rawBytes, UserProfile user) async {
    // Show auto-crop & beauty studio preview dialog
    final processedBytes = await AvatarPreviewDialog.show(context, rawBytes);

    if (processedBytes == null || !mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.citrusLime,
              ),
            ),
            SizedBox(width: 12),
            Text('Saving enhanced chef portrait...'),
          ],
        ),
        backgroundColor: AppColors.forestGreen,
        duration: Duration(seconds: 1),
      ),
    );

    // Save to local storage
    final localFilePath = await AvatarImageService.saveAvatarLocally(
      bytes: processedBytes,
      userId: user.id,
    );

    final updated = user.copyWith(avatarUrl: localFilePath);
    await ref.read(authNotifierProvider.notifier).updateProfile(updated);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.stars_rounded, color: AppColors.citrusLime),
              SizedBox(width: 8),
              Expanded(
                child: Text('Chef portrait updated beautifully! ✨'),
              ),
            ],
          ),
          backgroundColor: AppColors.forestGreen,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _handleAvatarTap(
    BuildContext context,
    WidgetRef ref,
    dynamic user,
  ) async {
    final action = await AvatarSourceSheet.show(
      context,
      hasExistingAvatar:
          user.avatarUrl != null && (user.avatarUrl as String).trim().isNotEmpty,
    );

    if (action == null || !context.mounted) return;

    if (action == AvatarSourceAction.remove) {
      await AvatarImageService.deleteLocalAvatar(user.avatarUrl as String?);
      final updated = user.copyWith(avatarUrl: '');
      await ref.read(authNotifierProvider.notifier).updateProfile(updated);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.info_outline_rounded, color: AppColors.citrusLime),
                SizedBox(width: 8),
                Text('Portrait reset to initial letter.'),
              ],
            ),
            backgroundColor: AppColors.forestGreen,
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    final pickerService = ref.read(avatarImageServiceProvider);
    final source = action == AvatarSourceAction.camera
        ? ImageSource.camera
        : ImageSource.gallery;

    try {
      final rawBytes = await pickerService.pickImageBytes(
        source: source,
        preferredCameraDevice: CameraDevice.front,
      );

      if (rawBytes == null || !context.mounted) return;

      if (user is UserProfile) {
        await _processAndSaveAvatar(rawBytes, user);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not update portrait: $e'),
            backgroundColor: AppColors.softCoral,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currentUser = ref.watch(currentUserProvider);
    final favoriteIds =
        ref.watch(favoritesNotifierProvider).value ?? <String>{};
    final allRecipes = ref.watch(allRecipesProvider).value ?? <Recipe>[];
    final userSubmissions = currentUser != null
        ? allRecipes
            .where((r) =>
                r.isCommunitySubmission &&
                (r.authorUid == currentUser.id ||
                    r.authorUid == currentUser.email ||
                    r.authorUid == 'local_chef' ||
                    r.authorUid == 'anonymous_chef'))
            .toList()
        : <Recipe>[];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/');
        }
      },
      child: Scaffold(
        appBar: AppBar(
        title: Text(
          currentUser != null ? 'Chef Profile' : 'CookMate Profile',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/'),
        ),
        actions: [
          if (currentUser != null)
            IconButton(
              tooltip: 'Sign Out',
              icon: const Icon(Icons.logout_rounded),
              onPressed: () => _showSignOutDialog(context, ref),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: currentUser == null
                  ? _buildGuestGateway(context, theme, isDark)
                  : _buildAuthenticatedProfile(
                      context,
                      theme,
                      isDark,
                      currentUser,
                      favoriteIds.length,
                      userSubmissions,
                      ref,
                    ),
            ),
          ),
        ),
      ),
    ),
  );
  }

  Widget _buildGuestGateway(
    BuildContext context,
    ThemeData theme,
    bool isDark,
  ) {
    return Column(
      children: [
        const SizedBox(height: 8),
        // Chef Guest Avatar with Glow
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppColors.accentGradient,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.citrusLime.withValues(alpha: 0.35),
                    blurRadius: 24,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppColors.primaryGradient,
                border: Border.all(
                  color: isDark ? AppColors.citrusLime : Colors.white,
                  width: 2.5,
                ),
              ),
              child: const Center(
                child: Text('👨‍🍳', style: TextStyle(fontSize: 44)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'Guest Chef Profile',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Text(
            'Sign in or register to unlock your culinary archive, secret personal recipes, and device synchronization.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Shiny Glass Card with Privileges Showcase
        ShinyGlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const AppLogoBadge(size: 32),
                  const SizedBox(width: 10),
                  Text(
                    'Chef Privileges',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildFeatureItem(
                icon: Icons.bookmark_added_rounded,
                title: 'Sync Saved Recipes',
                description: 'Bookmark recipes and access them offline anytime.',
                color: AppColors.softCoral,
                isDark: isDark,
              ),
              _buildFeatureItem(
                icon: Icons.tune_rounded,
                title: 'Runtime Ingredient Scaling',
                description: 'Scale ingredients dynamically per serving size.',
                color: AppColors.goldenAmber,
                isDark: isDark,
              ),
              _buildFeatureItem(
                icon: Icons.restaurant_menu_rounded,
                title: 'Publish Custom Dishes',
                description: 'Submit your culinary creations directly to the archive.',
                color: AppColors.forestGreen,
                isDark: isDark,
              ),
              _buildFeatureItem(
                icon: Icons.verified_user_rounded,
                title: 'Persistent Remember Me',
                description: 'Seamless password-protected access on this device.',
                color: const Color(0xFF2ECC71),
                isDark: isDark,
              ),
            ],
          ),
        ),

        const SizedBox(height: 18),

        // Sign In Action Button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: BounceTap(
              onTap: () => context.push('/sign-in'),
              child: Container(
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.forestGreen.withValues(alpha: 0.35),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.login_rounded, color: AppColors.citrusLime),
                    SizedBox(width: 8),
                    Text(
                      'Sign In to CookMate',
                      style: TextStyle(
                        color: AppColors.citrusLime,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Create Account Action Button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                side: BorderSide(
                  color: isDark ? AppColors.citrusLime : AppColors.forestGreen,
                  width: 1.5,
                ),
              ),
              icon: Icon(
                Icons.person_add_rounded,
                color: isDark ? AppColors.citrusLime : AppColors.forestGreen,
              ),
              label: Text(
                'Create New Chef Account',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: isDark ? AppColors.citrusLime : AppColors.forestGreen,
                ),
              ),
              onPressed: () => context.push('/sign-up'),
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildAuthenticatedProfile(
    BuildContext context,
    ThemeData theme,
    bool isDark,
    dynamic user,
    int savedCount,
    List<Recipe> userSubmissions,
    WidgetRef ref,
  ) {
    return Column(
      children: [
        const SizedBox(height: 8),
        // Authenticated Interactive Chef Avatar
        ChefAvatarView(
          avatarUrl: user.avatarUrl,
          name: user.name,
          size: 138,
          borderRadius: 34,
          isEditable: true,
          onTap: () => _handleAvatarTap(context, ref, user),
        ),
        const SizedBox(height: 8),
        BounceTap(
          onTap: () => _handleAvatarTap(context, ref, user),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.photo_camera_rounded,
                  size: 13,
                  color: isDark ? AppColors.citrusLime : AppColors.forestGreen,
                ),
                const SizedBox(width: 5),
                Text(
                  'Tap avatar to update portrait',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.citrusLime : AppColors.forestGreen,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),

        Text(
          user.name,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          user.email,
          style: TextStyle(
            fontSize: 14,
            color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
          ),
        ),
        const SizedBox(height: 8),

        // Tier Chip
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.citrusLime.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.citrusLime.withValues(alpha: 0.6),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.military_tech_rounded,
                color: AppColors.goldenAmber,
                size: 18,
              ),
              const SizedBox(width: 4),
              Text(
                user.skillLevel,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  color: AppColors.goldenAmber,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Stats Glass Card
        ShinyGlassCard(
          child: Row(
            children: [
              Expanded(
                child: _buildStatItem(
                    'Saved', '$savedCount', Icons.bookmark_rounded),
              ),
              _buildStatDivider(isDark),
              Expanded(
                child: _buildStatItem(
                    'Submissions', '${userSubmissions.length}', Icons.restaurant_menu_rounded),
              ),
              _buildStatDivider(isDark),
              Expanded(
                child: _buildStatItem(
                    'Diet Focus', 'Omnivore', Icons.eco_rounded),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // My Kitchen Creations Section
        ShinyGlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'My Kitchen Creations (${userSubmissions.length})',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  BounceTap(
                    onTap: () => context.push('/submit-recipe'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.citrusLime.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.citrusLime.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.add_rounded,
                            size: 14,
                            color: isDark
                                ? AppColors.citrusLime
                                : AppColors.forestGreen,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Add Recipe',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? AppColors.citrusLime
                                  : AppColors.forestGreen,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (userSubmissions.isNotEmpty) ...[
                ...userSubmissions.map((recipe) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: BounceTap(
                      onTap: () => context.push('/recipes/${recipe.id}'),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF142720)
                              : Colors.white.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.08)
                                : Colors.black.withValues(alpha: 0.06),
                          ),
                        ),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: SizedBox(
                                width: 50,
                                height: 50,
                                child: AppCachedNetworkImage(
                                  imageUrl: recipe.imageUrl,
                                  category: recipe.category,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    recipe.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    '${recipe.category} • ${recipe.totalMinutes} min • ${recipe.difficulty}',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      color: isDark
                                          ? AppColors.textMutedDark
                                          : AppColors.textMutedLight,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.chevron_right_rounded,
                              color: isDark
                                  ? AppColors.citrusLime
                                  : AppColors.forestGreen,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ] else ...[
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.citrusLime.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.restaurant_rounded,
                        color: AppColors.forestGreen,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Share Your Signature Creation',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            'Publish recipes with instant Chef AI auto-fill.',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: isDark
                                  ? AppColors.textMutedDark
                                  : AppColors.textMutedLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                    BounceTap(
                      onTap: () => context.push('/submit'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Create',
                          style: TextStyle(
                            color: AppColors.citrusLime,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Account Details Glass Card
        ShinyGlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Chef Settings & Security',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 14),
              const Material(
                color: Colors.transparent,
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.security_rounded),
                  title: Text('Authentication Mode'),
                  subtitle: Text('Secured with local hashed vault'),
                  trailing: Icon(
                    Icons.check_circle_rounded,
                    color: Color(0xFF2ECC71),
                  ),
                ),
              ),
              const Divider(height: 1),
              Material(
                color: Colors.transparent,
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.calendar_today_rounded),
                  title: const Text('Member Since'),
                  subtitle: Text(
                    '${user.joinedAt.year}-${user.joinedAt.month.toString().padLeft(2, '0')}-${user.joinedAt.day.toString().padLeft(2, '0')}',
                  ),
                ),
              ),
              const Divider(height: 1),
              Material(
                color: Colors.transparent,
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.vpn_key_rounded),
                  title: const Text('Change Password'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push('/sign-in'),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Sign Out Button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                side: BorderSide(
                  color: AppColors.softCoral.withValues(alpha: 0.8),
                ),
              ),
              icon: const Icon(
                Icons.logout_rounded,
                color: AppColors.softCoral,
              ),
              label: const Text(
                'Sign Out from this Device',
                style: TextStyle(
                  color: AppColors.softCoral,
                  fontWeight: FontWeight.w700,
                ),
              ),
              onPressed: () => _showSignOutDialog(context, ref),
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 20, color: AppColors.citrusLime),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildStatDivider(bool isDark) {
    return Container(
      width: 1,
      height: 36,
      color: isDark
          ? Colors.white.withValues(alpha: 0.12)
          : Colors.black.withValues(alpha: 0.08),
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: isDark
                        ? AppColors.textMutedDark
                        : AppColors.textMutedLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
