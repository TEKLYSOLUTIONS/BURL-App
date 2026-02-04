import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'api_service.dart';

/// Service for managing cricket coaching sessions
class SessionService {
  /// Create a new coaching session
  ///
  /// Example:
  /// ```dart
  /// await SessionService.createSession(
  ///   title: 'Batting Practice',
  ///   description: 'Focus on cover drives',
  ///   location: 'Cricket Academy - Pitch 2',
  ///   capacity: 18,
  ///   timeSlots: [
  ///     {'startTime': {'hour': 9, 'minute': 0}, 'durationMinutes': 90}
  ///   ],
  ///   selectedDays: ['2026-01-25'],
  ///   isRecurring: false,
  /// );
  /// ```
  static Future<Map<String, dynamic>> createSession({
    required String title,
    required String description,
    required String location,
    required int capacity,
    required List<Map<String, dynamic>> timeSlots,
    required List<String> selectedDays,
    required bool isRecurring,
    List<Map<String, dynamic>> explicitTimeSlots =
        const [], // New optional param
    List<String> participants = const [],
    double priceAmount = 0.0,
    bool pricePerPerson = true,
  }) async {
    try {
      final httpResponse = await ApiService.post('sessions', {
        'title': title,
        'description': description,
        'location': location,
        'capacity': capacity,
        'timeSlots': timeSlots,
        'explicitTimeSlots': explicitTimeSlots, // Pass to backend
        'selectedDays': selectedDays,
        'isRecurring': isRecurring,
        'participants': participants,
        'pricing': {
          'amount': priceAmount,
          'currency': 'USD',
          'pricePerPerson': pricePerPerson,
        },
      });

      final responseData =
          json.decode(httpResponse.body) as Map<String, dynamic>;

      if (responseData['status'] == 'success') {
        debugPrint(
          'Session created successfully: ${responseData['data']['_id']}',
        );
        return responseData['data'] as Map<String, dynamic>;
      } else {
        throw Exception(responseData['message'] ?? 'Failed to create session');
      }
    } catch (e) {
      debugPrint('Error creating session: $e');
      rethrow;
    }
  }

  /// Get all sessions for the authenticated coach
  ///
  /// Parameters:
  /// - type: 'upcoming', 'past', or 'all' (default: 'all')
  /// - limit: number of sessions to fetch (default: 20)
  /// - page: page number for pagination (default: 1)
  /// - status: filter by status ('draft', 'published', 'completed', 'cancelled')
  static Future<Map<String, dynamic>> getCoachSessions({
    String type = 'all',
    int limit = 20,
    int page = 1,
    String? status,
    DateTime? date,
  }) async {
    try {
      final queryParams = <String, String>{
        'type': type,
        'limit': limit.toString(),
        'page': page.toString(),
      };

      if (status != null && status.isNotEmpty) {
        queryParams['status'] = status;
      }

      if (date != null) {
        queryParams['date'] =
            "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
      }

      final queryString = queryParams.entries
          .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
          .join('&');

      final httpResponse = await ApiService.get('sessions?$queryString');
      final responseData =
          json.decode(httpResponse.body) as Map<String, dynamic>;

      if (responseData['status'] == 'success') {
        // Backend returns data as array directly, not nested in 'sessions' property
        final sessions = responseData['data'] as List<dynamic>;
        debugPrint('Fetched ${sessions.length} sessions (type: $type)');
        // Return in the format expected by the calling code
        return {
          'sessions': sessions,
          'total': responseData['total'] ?? sessions.length,
          'page': responseData['page'] ?? 1,
          'pages': responseData['pages'] ?? 1,
        };
      } else {
        throw Exception(responseData['message'] ?? 'Failed to fetch sessions');
      }
    } catch (e) {
      debugPrint('Error fetching coach sessions: $e');
      rethrow;
    }
  }

  /// Get a single session by ID
  static Future<Map<String, dynamic>> getSessionById(String sessionId) async {
    try {
      final httpResponse = await ApiService.get('sessions/$sessionId');
      final responseData =
          json.decode(httpResponse.body) as Map<String, dynamic>;

      if (responseData['status'] == 'success') {
        debugPrint('Fetched session: ${responseData['data']['title']}');
        return responseData['data'] as Map<String, dynamic>;
      } else {
        throw Exception(responseData['message'] ?? 'Failed to fetch session');
      }
    } catch (e) {
      debugPrint('Error fetching session by ID: $e');
      rethrow;
    }
  }

  /// Update an existing session
  ///
  /// Only the fields provided in `updates` will be changed
  static Future<Map<String, dynamic>> updateSession(
    String sessionId,
    Map<String, dynamic> updates,
  ) async {
    try {
      final httpResponse = await ApiService.put('sessions/$sessionId', updates);
      final responseData =
          json.decode(httpResponse.body) as Map<String, dynamic>;

      if (responseData['status'] == 'success') {
        debugPrint('Session updated successfully: $sessionId');
        return responseData['data'] as Map<String, dynamic>;
      } else {
        throw Exception(responseData['message'] ?? 'Failed to update session');
      }
    } catch (e) {
      debugPrint('Error updating session: $e');
      rethrow;
    }
  }

  /// Delete a session permanently
  ///
  /// Returns true if deletion was successful
  static Future<bool> deleteSession(String sessionId) async {
    try {
      final httpResponse = await ApiService.delete('sessions/$sessionId');

      // 204 No Content indicates success
      if (httpResponse.statusCode == 204) {
        debugPrint('Session deleted successfully: $sessionId');
        return true;
      }

      final responseData =
          json.decode(httpResponse.body) as Map<String, dynamic>;

      if (responseData['status'] == 'success') {
        debugPrint('Session deleted successfully: $sessionId');
        return true;
      } else {
        throw Exception(responseData['message'] ?? 'Failed to delete session');
      }
    } catch (e) {
      debugPrint('Error deleting session: $e');
      rethrow;
    }
  }

  /// Add players to a session
  ///
  /// Parameters:
  /// - sessionId: ID of the session
  /// - playerIds: List of player user IDs to add
  static Future<Map<String, dynamic>> addPlayersToSession(
    String sessionId,
    List<String> playerIds,
  ) async {
    try {
      final httpResponse = await ApiService.post(
        'sessions/$sessionId/players',
        {'playerIds': playerIds},
      );
      final responseData =
          json.decode(httpResponse.body) as Map<String, dynamic>;

      if (responseData['status'] == 'success') {
        debugPrint('Added ${playerIds.length} players to session $sessionId');
        return responseData['data'] as Map<String, dynamic>;
      } else {
        throw Exception(responseData['message'] ?? 'Failed to add players');
      }
    } catch (e) {
      debugPrint('Error adding players to session: $e');
      rethrow;
    }
  }

  /// Get session statistics for the coach
  ///
  /// Returns counts for upcoming, past, and total sessions
  static Future<Map<String, dynamic>> getSessionStats() async {
    try {
      final httpResponse = await ApiService.get('sessions/stats');
      final responseData =
          json.decode(httpResponse.body) as Map<String, dynamic>;

      if (responseData['status'] == 'success') {
        debugPrint('Fetched session stats: ${responseData['data']}');
        return responseData['data'] as Map<String, dynamic>;
      } else {
        throw Exception(responseData['message'] ?? 'Failed to fetch stats');
      }
    } catch (e) {
      debugPrint('Error fetching session stats: $e');
      rethrow;
    }
  }
}
