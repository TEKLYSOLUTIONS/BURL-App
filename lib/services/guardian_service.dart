import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../config/api_config.dart';
import 'api_service.dart'; // Reuse existing helper if possible, or direct http if needed

class GuardianService {
  static String get baseUrl => ApiConfig.baseUrl;

  // Notifier to trigger UI updates across screens (e.g., Home Dashboard)
  static final ValueNotifier<bool> playerUpdateNotifier = ValueNotifier(false);

  // Add a new minor player
  Future<Map<String, dynamic>> addPlayer({
    required String fullName,
    required String age,
    DateTime? dateOfBirth,
    String role = 'Batsman',
    String? battingStyle,
    String? bowlingStyle,
    String? jerseyNumber,
    String? teamName,
    String? profilePhoto,
  }) async {
    try {
      debugPrint('🛡️ Adding player: $fullName, Age: $age');

      final response = await ApiService.post('guardian/players', {
        'fullName': fullName,
        'age': age,
        'dateOfBirth': dateOfBirth?.toIso8601String(),
        'role': role,
        'battingStyle': battingStyle,
        'bowlingStyle': bowlingStyle,
        'jerseyNumber': jerseyNumber,
        'teamName': teamName,
        'profilePhoto': profilePhoto,
      });

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        debugPrint('✅ Player added successfully: ${data['data']['_id']}');
        return data['data'];
      } else {
        throw Exception('Failed to add player: ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ Error adding player: $e');
      rethrow;
    }
  }

  // Get all players managed by this guardian
  Future<List<dynamic>> getMyPlayers() async {
    try {
      debugPrint('📥 Fetching guardian players...');

      final response = await ApiService.get('guardian/players');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'] as List<dynamic>;
      } else {
        throw Exception('Failed to fetch players: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Error fetching players: $e');
      rethrow;
    }
  }

  // Get single player details
  Future<Map<String, dynamic>> getPlayerDetails(String playerId) async {
    try {
      final response = await ApiService.get('guardian/player/$playerId');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'];
      } else {
        throw Exception(
          'Failed to fetch player details: ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('❌ Error fetching player details: $e');
      rethrow;
    }
  }

  // Get guardian profile
  Future<Map<String, dynamic>> getProfile() async {
    try {
      final response = await ApiService.get('guardian/profile');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'];
      } else {
        throw Exception('Failed to fetch profile');
      }
    } catch (e) {
      debugPrint('❌ Error fetching profile: $e');
      rethrow;
    }
  }

  // Update guardian profile
  Future<Map<String, dynamic>> updateGuardianProfile(
      Map<String, dynamic> data) async {
    try {
      final response = await ApiService.put('guardian/profile', data);

      if (response.statusCode == 200) {
        final resData = jsonDecode(response.body);
        return resData['data'];
      } else {
        throw Exception('Failed to update guardian profile');
      }
    } catch (e) {
      debugPrint('❌ Error updating guardian profile: $e');
      rethrow;
    }
  }

  // Link existing player via email
  Future<void> linkPlayer(String email) async {
    try {
      final response = await ApiService.post('guardian/players/existing', {
        'email': email,
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('✅ Player linked successfully');
        playerUpdateNotifier.value = !playerUpdateNotifier.value;
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to link player');
      }
    } catch (e) {
      debugPrint('❌ Error linking player: $e');
      rethrow;
    }
  }

  // Update a player's profile
  Future<Map<String, dynamic>> updatePlayer(
    String playerId, {
    required String fullName,
    required String age,
    required String role,
    required String battingStyle,
    required String bowlingStyle,
    required String medicalIssues,
    String? profilePhoto,
  }) async {
    try {
      debugPrint('🔄 Updating player: $playerId');

      final body = {
        'fullName': fullName,
        'age': age,
        'role': role,
        'battingStyle': battingStyle,
        'bowlingStyle': bowlingStyle,
        'medicalIssues': medicalIssues,
      };
      if (profilePhoto != null) {
        body['profilePhoto'] = profilePhoto;
      }

      final response = await ApiService.put('guardian/player/$playerId', body);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('✅ Player updated successfully');
        // Trigger update notifier
        playerUpdateNotifier.value = !playerUpdateNotifier.value;
        return data['data'];
      } else {
        throw Exception('Failed to update player: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Error updating player: $e');
      rethrow;
    }
  }

  // Remove a player
  Future<void> removePlayer(String playerId) async {
    try {
      debugPrint('🗑️ Removing player: $playerId');

      final response = await ApiService.delete('guardian/player/$playerId');

      if (response.statusCode == 200) {
        debugPrint('✅ Player removed successfully');
        // Trigger update notifier
        playerUpdateNotifier.value = !playerUpdateNotifier.value;
      } else {
        throw Exception('Failed to remove player: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Error removing player: $e');
      rethrow;
    }
  }
}
