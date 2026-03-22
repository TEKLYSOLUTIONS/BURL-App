import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'api_service.dart';

/// Service for managing cricket coaching sessions
class _SessionCacheEntry {
  final Map<String, dynamic> data;
  final DateTime timestamp;

  _SessionCacheEntry({required this.data, required this.timestamp});
}

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
    // Wizard Fields
    String sessionType = 'one-time',
    List<String> focusAreas = const [],
    String skillLevel = 'All Levels',
    List<String> ageGroups = const [],
    Map<String, dynamic>?
        recurringPattern, // {startDate, endDate, daysOfWeek, ...}
    Map<String, dynamic>? pricing, // {model, amount, currency}
    Map<String, dynamic>? enrollmentSettings,
    String? cancellationPolicy,
    List<String> equipmentRequired = const [],
    List<Map<String, dynamic>> explicitTimeSlots = const [],
    List<String> participants = const [],
    // Legacy support (to be removed or mapped to pricing)
    double priceAmount = 0.0,
    bool pricePerPerson = true,
    String status = 'published', // Default to published
  }) async {
    try {
      final body = {
        'title': title,
        'description': description,
        'location': location,
        'capacity':
            capacity, // Backend now handles plain number (converted to {min:1, max:capacity})
        'timeSlots': timeSlots,
        'explicitTimeSlots': explicitTimeSlots,
        'selectedDays': selectedDays,
        'isRecurring': isRecurring,
        'participants': participants,
        // Wizard Fields
        'sessionType': sessionType,
        'focusAreas': focusAreas,
        'skillLevel': skillLevel,
        'ageGroups': ageGroups,
        'recurringPattern': recurringPattern,
        'enrollmentSettings': enrollmentSettings,
        'cancellationPolicy': cancellationPolicy,
        'equipmentRequired': equipmentRequired,
        'pricing': pricing ??
            {
              'amount': priceAmount,
              'currency': 'USD',
              'pricePerPerson': pricePerPerson,
              'model': 'per-session',
            },
        'status': status,
      };

      final httpResponse = await ApiService.post('sessions', body);

      final responseData =
          json.decode(httpResponse.body) as Map<String, dynamic>;

      if (responseData['status'] == 'success') {
        debugPrint(
          'Session created successfully: ${responseData['data']['_id']}',
        );
        invalidateCoachSessionsCache();
        invalidatePlayerSessionsCache();
        invalidateGuardianSessionsCache();
        return responseData['data'] as Map<String, dynamic>;
      } else {
        throw Exception(responseData['message'] ?? 'Failed to create session');
      }
    } catch (e) {
      debugPrint('Error creating session: $e');
      rethrow;
    }
  }

  /// Get sessions for the authenticated player, optionally filtered by date.
  static Future<Map<String, dynamic>> getPlayerSessions({
    int limit = 20,
    int page = 1,
    DateTime? date,
  }) async {
    final cacheKey = _buildCacheKey('player', limit, page, null, date);
    final cached = _playerSessionsCache[cacheKey];
    if (cached != null &&
        DateTime.now().difference(cached.timestamp) < _cacheTtl) {
      return Map<String, dynamic>.from(cached.data);
    }

    try {
      final queryParams = <String, String>{
        'limit': limit.toString(),
        'page': page.toString(),
      };

      if (date != null) {
        final localMidnight = DateTime(date.year, date.month, date.day);
        final localEndOfDay =
            DateTime(date.year, date.month, date.day, 23, 59, 59, 999);
        queryParams['startDate'] = localMidnight.toUtc().toIso8601String();
        queryParams['endDate'] = localEndOfDay.toUtc().toIso8601String();
      }

      final queryString = queryParams.entries
          .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
          .join('&');

      final httpResponse = await ApiService.get('sessions/player?$queryString');
      final responseData =
          json.decode(httpResponse.body) as Map<String, dynamic>;

      if (responseData['status'] == 'success') {
        final sessions = (responseData['sessions'] ??
            responseData['data'] ??
            []) as List<dynamic>;
        final result = {
          'sessions': sessions,
          'total': responseData['total'] ?? sessions.length,
          'page': responseData['page'] ?? 1,
          'pages': responseData['pages'] ?? 1,
        };

        _playerSessionsCache[cacheKey] = _SessionCacheEntry(
          data: result,
          timestamp: DateTime.now(),
        );

        return result;
      } else {
        throw Exception(
            responseData['message'] ?? 'Failed to fetch player sessions');
      }
    } catch (e) {
      debugPrint('Error fetching player sessions: $e');
      rethrow;
    }
  }

  /// Get sessions for the authenticated guardian's managed players, filtered by date.
  static Future<Map<String, dynamic>> getGuardianSessions({
    int limit = 20,
    int page = 1,
    DateTime? date,
  }) async {
    final cacheKey = _buildCacheKey('guardian', limit, page, null, date);
    final cached = _guardianSessionsCache[cacheKey];
    if (cached != null &&
        DateTime.now().difference(cached.timestamp) < _cacheTtl) {
      return Map<String, dynamic>.from(cached.data);
    }

    try {
      final queryParams = <String, String>{
        'limit': limit.toString(),
        'page': page.toString(),
      };

      if (date != null) {
        final localMidnight = DateTime(date.year, date.month, date.day);
        final localEndOfDay =
            DateTime(date.year, date.month, date.day, 23, 59, 59, 999);
        queryParams['startDate'] = localMidnight.toUtc().toIso8601String();
        queryParams['endDate'] = localEndOfDay.toUtc().toIso8601String();
      }

      final queryString = queryParams.entries
          .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
          .join('&');

      final httpResponse =
          await ApiService.get('sessions/guardian?$queryString');
      final responseData =
          json.decode(httpResponse.body) as Map<String, dynamic>;

      if (responseData['status'] == 'success') {
        final sessions = (responseData['sessions'] ??
            responseData['data'] ??
            []) as List<dynamic>;
        final result = {
          'sessions': sessions,
          'total': responseData['total'] ?? sessions.length,
          'page': responseData['page'] ?? 1,
          'pages': responseData['pages'] ?? 1,
        };

        _guardianSessionsCache[cacheKey] = _SessionCacheEntry(
          data: result,
          timestamp: DateTime.now(),
        );

        return result;
      } else {
        throw Exception(
            responseData['message'] ?? 'Failed to fetch guardian sessions');
      }
    } catch (e) {
      debugPrint('Error fetching guardian sessions: $e');
      rethrow;
    }
  }

  // ─── Cache ───────────────────────────────────────────────────────────────
  static final Map<String, _SessionCacheEntry> _coachSessionsCache = {};
  static final Map<String, _SessionCacheEntry> _playerSessionsCache = {};
  static final Map<String, _SessionCacheEntry> _guardianSessionsCache = {};
  static final Map<String, _SessionCacheEntry> _playerReportsCache = {};
  static const _cacheTtl = Duration(minutes: 5);

  static void invalidateCoachSessionsCache() {
    _coachSessionsCache.clear();
  }

  static void invalidatePlayerSessionsCache() {
    _playerSessionsCache.clear();
  }

  static void invalidateGuardianSessionsCache() {
    _guardianSessionsCache.clear();
  }

  static void invalidatePlayerReportsCache() {
    _playerReportsCache.clear();
  }

  static String _buildCacheKey(
      String type, int limit, int page, String? status, DateTime? date) {
    return '${type}_${limit}_${page}_${status ?? 'none'}_${date?.toIso8601String() ?? 'none'}';
  }
  // ─────────────────────────────────────────────────────────────────────────

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
    final cacheKey = _buildCacheKey(type, limit, page, status, date);
    final cached = _coachSessionsCache[cacheKey];
    if (cached != null &&
        DateTime.now().difference(cached.timestamp) < _cacheTtl) {
      return Map<String, dynamic>.from(cached.data);
    }

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
        // Build start/end of the selected LOCAL day in UTC ISO format.
        // Using just 'YYYY-MM-DD' causes the backend to parse it as UTC midnight,
        // which shifts the boundaries by the user's UTC offset (e.g., IST = +5:30
        // means a 9AM IST slot is stored as 03:30 UTC — it falls on the PREVIOUS
        // UTC day). Instead we send the local day's boundaries as UTC timestamps.
        final localMidnight = DateTime(date.year, date.month, date.day);
        final localEndOfDay =
            DateTime(date.year, date.month, date.day, 23, 59, 59, 999);
        // Convert to UTC then format as ISO string
        queryParams['startDate'] = localMidnight.toUtc().toIso8601String();
        queryParams['endDate'] = localEndOfDay.toUtc().toIso8601String();
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
        final result = {
          'sessions': sessions,
          'total': responseData['total'] ?? sessions.length,
          'page': responseData['page'] ?? 1,
          'pages': responseData['pages'] ?? 1,
        };

        _coachSessionsCache[cacheKey] = _SessionCacheEntry(
          data: result,
          timestamp: DateTime.now(),
        );

        return result;
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
        
        // Invalidate all session caches
        invalidateCoachSessionsCache();
        invalidatePlayerSessionsCache();
        invalidateGuardianSessionsCache();
        
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
        invalidateCoachSessionsCache();
        invalidatePlayerSessionsCache();
        invalidateGuardianSessionsCache();
        return true;
      }

      final responseData =
          json.decode(httpResponse.body) as Map<String, dynamic>;

      if (responseData['status'] == 'success') {
        debugPrint('Session deleted successfully: $sessionId');
        invalidateCoachSessionsCache();
        invalidatePlayerSessionsCache();
        invalidateGuardianSessionsCache();
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
        
        invalidateCoachSessionsCache();
        invalidatePlayerSessionsCache();
        invalidateGuardianSessionsCache();
        
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

  /// Update player attendance status
  static Future<Map<String, dynamic>> updateAttendance(
    String sessionId,
    String playerId,
    bool attended, {
    String? note,
  }) async {
    try {
      final body = <String, dynamic>{'attended': attended};
      if (note != null) {
        body['note'] = note;
      }

      final httpResponse = await ApiService.put(
        'sessions/$sessionId/players/$playerId/attendance',
        body,
      );
      final responseData =
          json.decode(httpResponse.body) as Map<String, dynamic>;

      if (responseData['status'] == 'success') {
        debugPrint('Attendance updated: $playerId -> $attended');
        invalidateCoachSessionsCache();
        invalidatePlayerSessionsCache();
        invalidateGuardianSessionsCache();
        return responseData['data'] as Map<String, dynamic>;
      } else {
        throw Exception(
          responseData['message'] ?? 'Failed to update attendance',
        );
      }
    } catch (e) {
      debugPrint('Error updating attendance: $e');
      rethrow;
    }
  }

  /// Update player report for a session
  static Future<Map<String, dynamic>> updatePlayerReport(
    String sessionId,
    String playerId,
    Map<String, dynamic> reportData,
  ) async {
    try {
      final httpResponse = await ApiService.put(
        'sessions/$sessionId/players/$playerId/report',
        reportData,
      );
      final responseData =
          json.decode(httpResponse.body) as Map<String, dynamic>;

      if (responseData['status'] == 'success') {
        debugPrint('Player report updated: $playerId');
        invalidateCoachSessionsCache();
        invalidatePlayerSessionsCache();
        invalidateGuardianSessionsCache();
        return responseData['data'] as Map<String, dynamic>;
      } else {
        throw Exception(
          responseData['message'] ?? 'Failed to update player report',
        );
      }
    } catch (e) {
      debugPrint('Error updating player report: $e');
      rethrow;
    }
  }

  /// Start a session (mark as in-progress)
  static Future<Map<String, dynamic>> startSession(String sessionId) async {
    try {
      final httpResponse = await ApiService.post(
        'sessions/$sessionId/start',
        {},
      );
      final responseData =
          json.decode(httpResponse.body) as Map<String, dynamic>;

      if (responseData['status'] == 'success') {
        debugPrint('Session started: $sessionId');
        invalidateCoachSessionsCache();
        invalidatePlayerSessionsCache();
        invalidateGuardianSessionsCache();
        return responseData['data'] as Map<String, dynamic>;
      } else {
        throw Exception(responseData['message'] ?? 'Failed to start session');
      }
    } catch (e) {
      debugPrint('Error starting session: $e');
      rethrow;
    }
  }

  /// Get all session reports for a specific player
  static Future<List<dynamic>> getPlayerSessionReports(String playerId) async {
    final cacheKey = 'reports_$playerId';
    final cached = _playerReportsCache[cacheKey];
    if (cached != null &&
        DateTime.now().difference(cached.timestamp) < _cacheTtl) {
      return cached.data['reports'] as List<dynamic>;
    }

    try {
      final httpResponse = await ApiService.get(
        'sessions/player-reports/$playerId',
      );
      final responseData =
          json.decode(httpResponse.body) as Map<String, dynamic>;

      if (httpResponse.statusCode == 200) {
        final reports = (responseData['data'] as List<dynamic>?) ?? [];
        _playerReportsCache[cacheKey] = _SessionCacheEntry(
          data: {'reports': reports},
          timestamp: DateTime.now(),
        );
        return reports;
      } else {
        throw Exception(
          responseData['message'] ?? 'Failed to fetch player reports',
        );
      }
    } catch (e) {
      debugPrint('Error fetching player session reports: $e');
      rethrow;
    }
  }

  /// Complete a session
  static Future<Map<String, dynamic>> completeSession(
    String sessionId, {
    String? sessionNotes,
  }) async {
    try {
      final httpResponse = await ApiService.post(
        'sessions/$sessionId/complete',
        {'sessionNotes': sessionNotes ?? ''},
      );
      final responseData =
          json.decode(httpResponse.body) as Map<String, dynamic>;

      if (responseData['status'] == 'success') {
        debugPrint('Session completed: $sessionId');
        invalidateCoachSessionsCache();
        invalidatePlayerSessionsCache();
        invalidateGuardianSessionsCache();
        return responseData['data'] as Map<String, dynamic>;
      } else {
        throw Exception(
          responseData['message'] ?? 'Failed to complete session',
        );
      }
    } catch (e) {
      debugPrint('Error completing session: $e');
      rethrow;
    }
  }
}
