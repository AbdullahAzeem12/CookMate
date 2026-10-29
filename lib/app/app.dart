import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/app_constants.dart';
import '../core/theme/app_theme.dart';
import '../features/auth/presentation/providers/auth_providers.dart';
import '../features/recipes/presentation/providers/recipe_providers.dart';
import 'router.dart';

class CookMateApp extends ConsumerStatefulWidget {
  const CookMateApp({super.key});

  @override
  ConsumerState<CookMateApp> createState() => _CookMateAppState();
}

class _CookMateAppState extends ConsumerState<CookMateApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkRecoveredAvatar();
    });
  }

  /// Recovers gallery or camera selection if Android killed MainActivity
  /// during external photo picker handoff.
  Future<void> _checkRecoveredAvatar() async {
    try {
      final pickerService = ref.read(avatarImageServiceProvider);
      final lostBytes = await pickerService.retrieveLostData();
      if (lostBytes != null && mounted) {
        ref.read(pendingAvatarBytesProvider.notifier).state = lostBytes;
        // Direct chef smoothly to profile to finalize beauty filter & save
        appRouter.push('/profile');
      }
    } catch (e) {
      debugPrint('No lost avatar data or recovery skipped: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: appRouter,
    );
  }
}
