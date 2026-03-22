import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'api_service.dart';

class DashboardService {
  // ─── Cache ───────────────────────────────────────────────────────────────
  static Map<String, dynamic>? _coachCache;
  static DateTime? _coachCacheTime;

  static Map<String, dynamic>? _playerCache;
  static DateTime? _playerCacheTime;

  static Map<String, dynamic>? _guardianCache;
  static DateTime? _guardianCacheTime;

  static const _cacheTtl = Duration(minutes: 5);

  static bool _isValid(DateTime? time) =>
      time != null && DateTime.now().difference(time) < _cacheTtl;

  static void invalidateCache() {
    _coachCache = null;
    _coachCacheTime = null;
    _playerCache = null;
    _playerCacheTime = null;
    _guardianCache = null;
    _guardianCacheTime = null;
  }
  // ─────────────────────────────────────────────────────────────────────────

  /// Get coach dashboard data (stats, upcoming sessions, recent activity)
  static Future<Map<String, dynamic>?> getCoachDashboard() async {
    if (_coachCache != null && _isValid(_coachCacheTime)) {
      return Map<String, dynamic>.from(_coachCache!);
    }
    try {
      final response = await ApiService.get('dashboard/coach');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _coachCache = data['data'];
        _coachCacheTime = DateTime.now();
        return data['data'];
      }
      return null;
    } catch (e) {
      debugPrint('Coach dashboard error: $e');
      return null;
    }
  }

  /// Get player dashboard data
  static Future<Map<String, dynamic>?> getPlayerDashboard() async {
    if (_playerCache != null && _isValid(_playerCacheTime)) {
      return Map<String, dynamic>.from(_playerCache!);
    }
    try {
      final response = await ApiService.get('dashboard/player');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _playerCache = data['data'];
        _playerCacheTime = DateTime.now();
        return data['data'];
      }
      return null;
    } catch (e) {
      debugPrint('Player dashboard error: $e');
      return null;
    }
  }

  /// Get guardian dashboard data
  static Future<Map<String, dynamic>?> getGuardianDashboard() async {
    if (_guardianCache != null && _isValid(_guardianCacheTime)) {
      return Map<String, dynamic>.from(_guardianCache!);
    }
    try {
      final response = await ApiService.get('dashboard/guardian');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _guardianCache = data['data'];
        _guardianCacheTime = DateTime.now();
        return data['data'];
      }
      return null;
    } catch (e) {
      debugPrint('Guardian dashboard error: $e');
      return null;
    }
  }
}
