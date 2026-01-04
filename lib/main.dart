import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'config/theme.dart';
import 'navigation/app_router.dart';

void main() {
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
