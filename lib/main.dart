import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'config/theme.dart';
import 'navigation/app_router.dart';
import 'providers/theme_provider.dart';
import 'widgets/offline_banner.dart';
import 'services/startup_service.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Stripe (only on mobile, as web throws UnsupportedError without flutter_stripe_web)
  if (!kIsWeb) {
    Stripe.publishableKey =
        'pk_test_51SuC7930IZOlKyebl2FVo2GzcjPwoYVcT4rDBh1mXeLlLkj52RXfuVvSwTdUztN4aVgPM2yoXm0DxlxoZIAhzhyN00cgqZiTyU';
  }

  // Initialize Firebase
  try {
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);
  } catch (e) {
    debugPrint('Firebase init error: $e');
  }

  runApp(const ProviderScope(child: CoachingApp()));

  // Initialize push notifications and location AFTER the app is visible.
  // Doing this before runApp blocks the UI if getToken() hangs on iOS.
  StartupService.initializeAppStartup().catchError(
    (e) => debugPrint('Startup service error: $e'),
  );
}

class CoachingApp extends ConsumerWidget {
  const CoachingApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);

    return MaterialApp.router(
      title: 'CricLy',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: AppRouter.router,
      builder: (context, child) {
        return Column(
          children: [
            const GlobalOfflineBanner(),
            Expanded(child: child ?? const SizedBox.shrink()),
          ],
        );
      },
    );
  }
}
