import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class AuthService {
  static Future<bool> login(String email, String password) async {
    try {
      final response = await ApiService.post('auth/login', {
        'email': email,
        'password': password,
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['token'];

        final user = data['user'];
        final userName = user['fullName'] ?? 'Coach';
        final userRole = user['role'] ?? 'coach';

        // Save token & user details to shared preferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', token);
        await prefs.setString('user_name', userName);
        await prefs.setString('user_role', userRole);

        return true;
      } else {
        return false;
      }
    } catch (e) {
      debugPrint('Login error: $e');
      return false;
    }
  }

  static Future<bool> register(
    String name,
    String email,
    String password,
    String role,
  ) async {
    try {
      final response = await ApiService.post('auth/register', {
        'name': name,
        'email': email,
        'password': password,
        'role': role,
      });

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final token = data['token'];

        final user = data['user'];
        final userName = user['fullName'] ?? name;
        final userRole = user['role'] ?? role;

        // Save token & user details to shared preferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', token);
        await prefs.setString('user_name', userName);
        await prefs.setString('user_role', userRole);

        return true;
      } else {
        return false;
      }
    } catch (e) {
      debugPrint('Registration error: $e');
      return false;
    }
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Clear all data (token, name, role)
  }

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey('auth_token');
  }

  static Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_name');
  }

  static Future<String?> getUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_role');
  }

  static Future<void> updateStoredUserData(String name, String role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', name);
    await prefs.setString('user_role', role);
  }

  static Future<bool> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    try {
      final response = await ApiService.post('auth/change-password', {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      });

      if (response.statusCode == 200) {
        return true;
      } else {
        final data = jsonDecode(response.body);
        throw Exception(data['message'] ?? 'Failed to change password');
      }
    } catch (e) {
      debugPrint('Change password error: $e');
      rethrow;
    }
  }
}
