import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../config/api_config.dart';

// ─── Background handler (must be a top-level function) ───────────────────────
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Firebase is already initialised by main() before this can fire.
  debugPrint('📬 Background push received: ${message.notification?.title}');
}
// ─────────────────────────────────────────────────────────────────────────────

class PushNotificationService {
  PushNotificationService._();

  static final _messaging = FirebaseMessaging.instance;

  /// Call once from main() after Firebase.initializeApp().
  /// Registers the background handler, requests permission, grabs the token,
  /// and wires foreground + tap listeners.
  static Future<void> initialize() async {
    // Avoid missing plugin exception on unsupported platforms (like Windows)
    if (!kIsWeb && !(Platform.isAndroid || Platform.isIOS || Platform.isMacOS)) {
      debugPrint('🔕 Push notifications not supported on this platform');
      return;
    }

    // Register background handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Request permission (iOS shows a dialog; Android 13+ too)
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      debugPrint('🔕 Push notifications denied by user');
      return;
    }

    debugPrint('🔔 Push permission: ${settings.authorizationStatus}');

    // Get and register the token
    await refreshToken();

    // Listen for token refreshes (e.g. app reinstall)
    _messaging.onTokenRefresh.listen((newToken) {
      debugPrint('🔄 FCM token refreshed');
      _sendTokenToBackend(newToken);
    });

    // Foreground message handler
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Tap from background state
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // Tap from terminated state
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage);
    }
  }

  /// Call this after every login to (re-)register the current token.
  static Future<void> refreshToken() async {
    if (!kIsWeb && !(Platform.isAndroid || Platform.isIOS || Platform.isMacOS)) {
      return;
    }

    try {
      final token = await _messaging.getToken();
      if (token != null) {
        debugPrint('📱 FCM token: ${token.substring(0, 20)}...');
        await _sendTokenToBackend(token);
      }
    } catch (e) {
      debugPrint('FCM token error: $e');
    }
  }

  // ── Private helpers ────────────────────────────────────────────────────────

  static Future<void> _sendTokenToBackend(String token) async {
    try {
      final secureStorage = const FlutterSecureStorage();
      final authToken = await secureStorage.read(key: 'auth_token');
      if (authToken == null) return; // Not logged in yet

      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/users/fcm-token'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: jsonEncode({'token': token}),
      );

      if (response.statusCode == 200) {
        debugPrint('✅ FCM token sent to backend');
      } else {
        debugPrint('⚠️ FCM token backend response: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('FCM token backend error: $e');
    }
  }

  /// Shows an in-app banner when a push arrives while the app is open.
  static void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('📩 Foreground push: ${message.notification?.title}');

    final context = _navigatorKey?.currentContext;
    if (context == null) return;

    final title = message.notification?.title ?? '';
    final body = message.notification?.body ?? '';
    final data = message.data;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: const Color(0xFF1A1F36),
        content: Row(
          children: [
            const Text('🔔', style: TextStyle(fontSize: 18)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (title.isNotEmpty)
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  if (body.isNotEmpty)
                    Text(
                      body,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        action: data['route'] != null
            ? SnackBarAction(
                label: 'View',
                textColor: const Color(0xFF4FC3F7),
                onPressed: () => _navigateTo(context, data['route']!),
              )
            : null,
      ),
    );
  }

  /// Handles taps on a push notification (from background or terminated).
  static void _handleNotificationTap(RemoteMessage message) {
    debugPrint('👆 Push tapped: ${message.data}');
    final context = _navigatorKey?.currentContext;
    if (context == null) return;

    final route = message.data['route'];
    if (route != null) {
      _navigateTo(context, route);
    }
  }

  static void _navigateTo(BuildContext context, String route) {
    try {
      // Use GoRouter if available via context; fallback to Navigator push path
      Navigator.of(context, rootNavigator: true).pushNamed(route);
    } catch (_) {
      // GoRouter navigation if Navigator.pushNamed isn't registered
      debugPrint('Navigation target: $route');
    }
  }

  // Navigator key injected from main.dart so we can get a context anywhere
  static GlobalKey<NavigatorState>? _navigatorKey;

  static void setNavigatorKey(GlobalKey<NavigatorState> key) {
    _navigatorKey = key;
  }
}
