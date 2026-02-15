import 'dart:convert';
import 'api_service.dart';

class CoachService {
  /// Get all players assigned to the coach
  static Future<Map<String, dynamic>> getCoachPlayers() async {
    try {
      final response = await ApiService.get('coach/players');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data'] ?? {};
      } else {
        throw Exception('Failed to fetch players: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching coach players: $e');
    }
  }

  /// Get coach profile
  static Future<Map<String, dynamic>?> getCoachProfile() async {
    try {
      final response = await ApiService.get('coach/profile');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to fetch profile: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching coach profile: $e');
    }
  }

  /// Update coach profile
  static Future<Map<String, dynamic>?> updateCoachProfile(
    Map<String, dynamic> profileData,
  ) async {
    try {
      final response = await ApiService.put('coach/profile', profileData);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to update profile: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error updating coach profile: $e');
    }
  }

  /// Get coach availability
  static Future<Map<String, dynamic>> getCoachAvailability() async {
    try {
      final response = await ApiService.get('coach/availability');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data'] ?? {};
      } else {
        throw Exception('Failed to fetch availability: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching coach availability: $e');
    }
  }

  /// Update coach availability (recurring schedule and blocked dates)
  static Future<Map<String, dynamic>> updateCoachAvailability(
    Map<String, dynamic> availabilityData,
  ) async {
    try {
      final response = await ApiService.put(
        'coach/availability',
        availabilityData,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data'] ?? {};
      } else {
        throw Exception(
          'Failed to update availability: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error updating coach availability: $e');
    }
  }

  /// Add a blocked date
  static Future<Map<String, dynamic>> addBlockedDate(
    Map<String, dynamic> blockedDateData,
  ) async {
    try {
      final response = await ApiService.post(
        'coach/availability/blocked-date',
        blockedDateData,
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data'] ?? {};
      } else {
        throw Exception('Failed to add blocked date: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error adding blocked date: $e');
    }
  }

  /// Remove a blocked date
  static Future<void> removeBlockedDate(String blockedDateId) async {
    try {
      final response = await ApiService.delete(
        'coach/availability/blocked-date/$blockedDateId',
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to remove blocked date: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error removing blocked date: $e');
    }
  }

  /// Get session settings
  static Future<Map<String, dynamic>> getSessionSettings() async {
    try {
      final response = await ApiService.get('coach/settings/session');
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data'] ?? {};
      } else {
        throw Exception(
          'Failed to fetch session settings: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error fetching session settings: $e');
    }
  }

  /// Update session settings
  static Future<Map<String, dynamic>> updateSessionSettings(
    Map<String, dynamic> settingsData,
  ) async {
    try {
      final response = await ApiService.put(
        'coach/settings/session',
        settingsData,
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data'] ?? {};
      } else {
        throw Exception(
          'Failed to update session settings: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error updating session settings: $e');
    }
  }
}
