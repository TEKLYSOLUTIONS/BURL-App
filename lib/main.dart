import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'config/theme.dart';
import 'navigation/app_router.dart';

import 'package:flutter_stripe/flutter_stripe.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Stripe
  Stripe.publishableKey =
      'pk_test_51SuC7930IZOlKyebl2FVo2GzcjPwoYVcT4rDBh1mXeLlLkj52RXfuVvSwTdUztN4aVgPM2yoXm0DxlxoZIAhzhyN00cgqZiTyU';

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const ProviderScope(child: CoachingApp()));
}

class CoachingApp extends StatelessWidget {
  const CoachingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Coach Connect',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light, // Force light theme (Pearl White)
      routerConfig: AppRouter.router,
    );
  }
}
