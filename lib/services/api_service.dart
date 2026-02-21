import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../config/api_config.dart';

class ApiService {
  static Future<Map<String, String>> _getHeaders() async {
    String? token;

    // First try to get a fresh token from Firebase (if logged in via Firebase/Apple/Google)
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // getIdToken() automatically refreshes the token if it has expired
        token = await user.getIdToken();

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

  static Future<http.Response> get(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
  }) async {
    final headers = await _getHeaders();
    final url = Uri.parse(
      '${ApiConfig.baseUrl}/$endpoint',
    ).replace(queryParameters: queryParameters);
    return await http.get(url, headers: headers);
  }

  static Future<http.Response> post(
    String endpoint,
    Map<String, dynamic> data,
  ) async {
    final headers = await _getHeaders();
    final url = Uri.parse('${ApiConfig.baseUrl}/$endpoint');
    return await http.post(url, headers: headers, body: jsonEncode(data));
  }

  static Future<http.Response> put(
    String endpoint,
    Map<String, dynamic> data,
  ) async {
    final headers = await _getHeaders();
    final url = Uri.parse('${ApiConfig.baseUrl}/$endpoint');
    return await http.put(url, headers: headers, body: jsonEncode(data));
  }

  static Future<http.Response> delete(String endpoint) async {
    final headers = await _getHeaders();
    final url = Uri.parse('${ApiConfig.baseUrl}/$endpoint');
    return await http.delete(url, headers: headers);
  }
}
