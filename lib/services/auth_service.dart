import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import 'firebase_auth_service.dart';
import 'profile_service.dart';
import 'dashboard_service.dart';
import 'session_service.dart';
import 'coach_service.dart';
import 'booking_service.dart';

class AuthService {
  // Helper to clear all static caches to prevent cross-account data leaks
  static void _clearAllStaticCaches() {
    ProfileService.invalidateCache();
    DashboardService.invalidateCache();
    
    SessionService.invalidateCoachSessionsCache();
    SessionService.invalidatePlayerSessionsCache();
    SessionService.invalidateGuardianSessionsCache();
    SessionService.invalidatePlayerReportsCache();
    
    CoachService.invalidateAvailabilityCache();
    CoachService.invalidateSessionSettingsCache();
    
    BookingService.invalidatePlayerBookingsCache();
    BookingService.invalidateCoachBookingsCache();
  }

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
        final userId = user['id'] ?? user['_id'];

        // Save token & user details to shared preferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', token);
        await prefs.setString('user_name', userName);
        await prefs.setString('user_role', userRole);
        if (userId != null) {
          await prefs.setString('user_id', userId);
        }

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
        final userId = user['id'] ?? user['_id'];

        // Save token & user details to shared preferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', token);
        await prefs.setString('user_name', userName);
        await prefs.setString('user_role', userRole);
        if (userId != null) {
          await prefs.setString('user_id', userId);
        }

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
    await prefs.clear(); // Clear all data (token, name, role, id)
    _clearAllStaticCaches(); // Prevent cross-account data leak
  }

  /// Full sign-out: clears SharedPreferences AND signs out of Firebase/Google.
  /// Use this for every logout button in the app.
  static Future<void> signOutCompletely() async {
    try {
      // Clear local session data
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      _clearAllStaticCaches(); // Prevent cross-account data leak
      // Sign out of Firebase to prevent Router redirects
      final FirebaseAuthService firebaseAuthService = FirebaseAuthService();
      await firebaseAuthService.signOut();
    } catch (_) {}
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

  static Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_id');
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

  /// Returns null on success, or an error message string if blocked/failed.
  static Future<String?> deleteAccount() async {
    try {
      final response = await ApiService.delete('users/me');

      if (response.statusCode == 200) {
        // Also delete the Firebase account so it can't be used to log in again
        try {
          final FirebaseAuthService firebaseAuthService = FirebaseAuthService();
          await firebaseAuthService.deleteCurrentUser();
        } catch (e) {
          debugPrint('⚠️ Could not delete Firebase account: $e');
        }
        await signOutCompletely();
        return null; // success
      } else {
        // Try to extract the server's message (e.g. the active-bookings block)
        try {
          final body = jsonDecode(response.body) as Map<String, dynamic>;
          return (body['message'] as String?) ?? 'Failed to delete account.';
        } catch (_) {
          return 'Failed to delete account. Please try again later.';
        }
      }
    } catch (e) {
      debugPrint('Delete account error: $e');
      return 'Failed to delete account. Please try again later.';
    }
  }
}
