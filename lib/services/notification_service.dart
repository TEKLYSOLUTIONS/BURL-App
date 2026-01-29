import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'api_service.dart';

class NotificationService {
  /// Get notifications for authenticated user
  static Future<Map<String, dynamic>> getNotifications({
    String category = 'all',
    bool unreadOnly = false,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final queryParams = <String, String>{
        'category': category,
        'unreadOnly': unreadOnly.toString(),
        'page': page.toString(),
        'limit': limit.toString(),
      };

      final queryString = queryParams.entries
          .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
          .join('&');

      final response = await ApiService.get('notifications?$queryString');
      final data = json.decode(response.body);

      if (data['success'] == true) {
        debugPrint('Fetched ${data['data']['notifications'].length} notifications');
        return data['data'] as Map<String, dynamic>;
      } else {
        throw Exception(data['message'] ?? 'Failed to fetch notifications');
      }
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
      rethrow;
    }
  }

  /// Get unread notification count
  static Future<int> getUnreadCount() async {
    try {
      final response = await ApiService.get('notifications/unread-count');
      final data = json.decode(response.body);

      if (data['success'] == true) {
        return data['data']['count'] as int;
      } else {
        throw Exception(data['message'] ?? 'Failed to get unread count');
      }
    } catch (e) {
      debugPrint('Error getting unread count: $e');
      return 0;
    }
  }

  /// Mark notification as read
  static Future<void> markAsRead(String notificationId) async {
    try {
      final response = await ApiService.put(
        'notifications/$notificationId/read',
        {},
      );
      final data = json.decode(response.body);

      if (data['success'] != true) {
        throw Exception(data['message'] ?? 'Failed to mark as read');
      }
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
      rethrow;
    }
  }

  /// Mark all notifications as read
  static Future<void> markAllAsRead() async {
    try {
      final response = await ApiService.put('notifications/mark-all-read', {});
      final data = json.decode(response.body);

      if (data['success'] != true) {
        throw Exception(data['message'] ?? 'Failed to mark all as read');
      }
    } catch (e) {
      debugPrint('Error marking all as read: $e');
      rethrow;
    }
  }

  /// Delete notification
  static Future<void> deleteNotification(String notificationId) async {
    try {
      final response = await ApiService.delete('notifications/$notificationId');
      final data = json.decode(response.body);

      if (data['success'] != true) {
        throw Exception(data['message'] ?? 'Failed to delete notification');
      }
    } catch (e) {
      debugPrint('Error deleting notification: $e');
      rethrow;
    }
  }

  /// Helper to map icon strings from backend to Flutter IconData
  static Map<String, dynamic> getIconData(String iconName, String color, String bg) {
    // This is a simplified mapping - expand as needed
    final iconMap = {
      'calendar_today': {'icon': 'calendar_today', 'code': 0xe935},
      'check_circle': {'icon': 'check_circle', 'code': 0xe86c},
      'cancel': {'icon': 'cancel', 'code': 0xe5c9},
      'alarm': {'icon': 'alarm', 'code': 0xe855},
      'update': {'icon': 'update', 'code': 0xf06a},
      'event_busy': {'icon': 'event_busy', 'code': 0xe946},
      'payment': {'icon': 'payment', 'code': 0xe8a1},
      'hourglass_empty': {'icon': 'hourglass_empty', 'code': 0xe88b},
      'star': {'icon': 'star', 'code': 0xe838},
      'comment': {'icon': 'comment', 'code': 0xe0b9},
      'mail': {'icon': 'mail', 'code': 0xe158},
      'emoji_events': {'icon': 'emoji_events', 'code': 0xea65},
      'info': {'icon': 'info', 'code': 0xe88e},
    };

    return iconMap[iconName] ?? iconMap['info']!;
  }
}
