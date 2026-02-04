import 'dart:convert';
import 'api_service.dart';

/// Service for managing user profile operations
class ProfileService {
  /// Get current user's profile
  /// Returns user object with populated role-specific profile
  static Future<Map<String, dynamic>> getProfile() async {
    try {
      final response = await ApiService.get('users/profile');

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        final Map<String, dynamic> user = Map<String, dynamic>.from(
          data['user'],
        );
        final Map<String, dynamic>? profile = data['profile'] != null
            ? Map<String, dynamic>.from(data['profile'])
            : null;

        // If profile data is separate, merge it into user object
        // This handles the format returned by getProfile API
        if (profile != null) {
          final String role = user['role'] ?? '';
          if (role == 'coach') {
            user['coachProfile'] = profile;
          } else if (role == 'player') {
            user['playerProfile'] = profile;
          } else if (role == 'guardian') {
            user['guardianProfile'] = profile;
          }
        }

        return user;
      } else {
        throw Exception(data['message'] ?? 'Failed to fetch profile');
      }
    } catch (e) {
      throw Exception('Error fetching profile: $e');
    }
  }

  /// Update current user's profile
  ///
  /// [profileData] - Map containing fields to update:
  ///   - fullName
  ///   - email
  ///   - phone
  ///   - profileImage
  ///   - bio (coach only)
  ///   - specializations (coach only)
  ///   - achievements (coach only)
  ///   - playingPosition (player only)
  ///   - skillLevel (player only)
  static Future<Map<String, dynamic>> updateProfile(
    Map<String, dynamic> profileData,
  ) async {
    try {
      final response = await ApiService.put('users/profile', profileData);

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        return data['user'];
      } else {
        throw Exception(data['message'] ?? 'Failed to update profile');
      }
    } catch (e) {
      throw Exception('Error updating profile: $e');
    }
  }

  /// Update profile image (mock implementation)
  ///
  /// In a real app, this would upload the image file to cloud storage
  /// For now, it returns a mock URL
  static Future<String> updateProfileImage() async {
    try {
      final response = await ApiService.put('users/profile/image', {});

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        return data['imageUrl'];
      } else {
        throw Exception(data['message'] ?? 'Failed to update profile image');
      }
    } catch (e) {
      throw Exception('Error updating profile image: $e');
    }
  }
}
