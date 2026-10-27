import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Attempt Firebase initialization if configured, otherwise fallback to offline mode
  try {
    await Firebase.initializeApp();
  } catch (_) {
    // Offline-first fallback: seed JSON dataset and SharedPreferences remain 100% active
  }

  runApp(const ProviderScope(child: CookMateApp()));
}
