import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../config/api_config.dart';
import 'auth_service.dart';
import '../navigation/app_router.dart';

class ApiService {
  static Future<Map<String, String>> _getHeaders({bool forceRefresh = false}) async {
    String? token;

    // First try to get a fresh token from Firebase (if logged in via Firebase/Apple/Google)
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Pass forceRefresh=true to bypass cached expired tokens
        token = await user.getIdToken(forceRefresh);

        // Save the fresh token to SharedPreferences
        if (token != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('auth_token', token);
        }
      }
    } catch (_) {
      // Ignore firebase auth errors here, fallback to SharedPreferences
    }

    // Fallback to SharedPreferences if Firebase token is unavailable
    if (token == null) {
      final prefs = await SharedPreferences.getInstance();
      token = prefs.getString('auth_token');
    }

    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Executes [request] with fresh headers. On a 401, force-refreshes the
  /// Firebase ID token and retries exactly once to handle expired cached tokens.
  static Future<http.Response> _withTokenRetry(
    String endpoint,
    Future<http.Response> Function(Map<String, String> headers) request,
  ) async {
    var headers = await _getHeaders();
    var response = await request(headers);

    if (response.statusCode == 401 && !endpoint.startsWith('auth/')) {
      // Token was expired/invalid — force a new token from Firebase and retry
      headers = await _getHeaders(forceRefresh: true);
      response = await request(headers);

      if (response.statusCode == 401) {
        // Still unauthorized after retry, clear session and redirect to welcome
        try {
          await AuthService.signOutCompletely();
          AppRouter.router.go('/welcome');
        } catch (e) {
          // Ignore router errors
        }
      }
    }

    return response;
  }

  static Future<http.Response> get(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
  }) async {
    final url = Uri.parse(
      '${ApiConfig.baseUrl}/$endpoint',
    ).replace(queryParameters: queryParameters);
    return _withTokenRetry(endpoint, (headers) => http.get(url, headers: headers));
  }

  static Future<http.Response> post(
    String endpoint,
    Map<String, dynamic> data,
  ) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/$endpoint');
    return _withTokenRetry(
      endpoint,
      (headers) => http.post(url, headers: headers, body: jsonEncode(data)),
    );
  }

  static Future<http.Response> put(
    String endpoint,
    Map<String, dynamic> data,
  ) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/$endpoint');
    return _withTokenRetry(
      endpoint,
      (headers) => http.put(url, headers: headers, body: jsonEncode(data)),
    );
  }

  static Future<http.Response> delete(String endpoint) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/$endpoint');
    return _withTokenRetry(
      endpoint,
      (headers) => http.delete(url, headers: headers),
    );
  }
}
