import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'api_service.dart';

class DashboardService {
  /// Get coach dashboard data (stats, upcoming sessions, recent activity)
  static Future<Map<String, dynamic>?> getCoachDashboard() async {
    try {
      final response = await ApiService.get('dashboard/coach');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
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
    try {
      final response = await ApiService.get('dashboard/player');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
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
    try {
      final response = await ApiService.get('dashboard/guardian');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'];
      }
      return null;
    } catch (e) {
      debugPrint('Guardian dashboard error: $e');
      return null;
    }
  }
}
