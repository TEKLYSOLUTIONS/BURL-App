import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../config/api_config.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
      ),
    );

    _controller.forward();

    // Check auth status immediately without artificial delay
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    // Wait for animation before routing
    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;

    // ✅ Firebase is the primary source of truth.
    // Its session persists on-device indefinitely until explicit signOut().
    final firebaseUser = FirebaseAuth.instance.currentUser;

    if (firebaseUser == null) {
      // No Firebase session — user must log in
      if (mounted) context.go('/welcome');
      return;
    }

    // Firebase session valid — restore role from local cache
    final prefs = await SharedPreferences.getInstance();
    String? role = prefs.getString('user_role');

    // If role is missing (app update / OS wiped prefs),
    // re-fetch it from the API using the live Firebase token.
    if (role == null || role.isEmpty) {
      try {
        final token = await firebaseUser.getIdToken();
        final response = await http.get(
          Uri.parse('${ApiConfig.baseUrl}/users/profile'),
          headers: {'Authorization': 'Bearer $token'},
        ).timeout(const Duration(seconds: 5));
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          role = data['user']?['role'] as String?;
          final name = data['user']?['fullName'] as String?;
          final uid = (data['user']?['_id'] ?? data['user']?['id']) as String?;
          if (role != null) await prefs.setString('user_role', role);
          if (name != null) await prefs.setString('user_name', name);
          if (uid != null) await prefs.setString('user_id', uid);
          if (token != null) {
            final secureStorage = const FlutterSecureStorage();
            await secureStorage.write(key: 'auth_token', value: token);
          }
        }
      } catch (_) {
        // Network unavailable — still route to home; ApiService handles 401s
      }
    }

    if (!mounted) return;
    switch (role) {
      case 'coach':
        context.go('/coach/home');
        break;
      case 'guardian':
        context.go('/guardian/home');
        break;
      default:
        context.go('/player/home');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark 
        ? const Color(0xFF0E1A2C) 
        : Theme.of(context).scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: bgColor,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              color: bgColor,
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  'assets/images/splash screen.jpg',
                  fit: BoxFit.fitHeight,
                ),
                // Overlay loading spinner
                Positioned(
                  bottom: 100, // Adjust distance from bottom as needed
                  left: 0,
                  right: 0,
                  child: Center(
                    child: SizedBox(
                      width: 40,
                      height: 40,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
