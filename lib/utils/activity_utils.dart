import 'package:flutter/material.dart';

class ActivityUtils {
  /// Get icon based on activity type
  static IconData getActivityIcon(String? type) {
    switch (type) {
      case 'session_completed':
      case 'session_created':
        return Icons.calendar_today;
      case 'player_joined':
      case 'player_left':
        return Icons.person_add;
      case 'injury_update':
        return Icons.local_hospital;
      case 'schedule_change':
        return Icons.update;
      case 'performance_logged':
        return Icons.directions_run;
      case 'attendance_marked':
        return Icons.check_circle;
      default:
        return Icons.notifications;
    }
  }

  /// Get icon color based on activity type
  static Color getActivityIconColor(String? type) {
    switch (type) {
      case 'session_completed':
      case 'session_created':
        return Colors.blue;
      case 'player_joined':
        return Colors.green;
      case 'player_left':
        return Colors.grey;
      case 'injury_update':
        return Colors.red;
      case 'schedule_change':
        return Colors.orange;
      case 'performance_logged':
        return Colors.purple;
      case 'attendance_marked':
        return Colors.teal;
      default:
        return Colors.blueGrey;
    }
  }

  /// Get background color for activity icon
  static Color getActivityBgColor(String? type) {
    final color = getActivityIconColor(type);
    return color.withValues(alpha: 0.1);
  }
}
