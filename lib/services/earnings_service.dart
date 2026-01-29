import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'api_service.dart';

class EarningsService {
  /// Get coach's total earnings
  static Future<Map<String, dynamic>> getTotalEarnings() async {
    try {
      final response = await ApiService.get('earnings/total');
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data'] ?? {};
      } else {
        throw Exception('Failed to load total earnings');
      }
    } catch (e) {
      debugPrint('Get total earnings error: $e');
      rethrow;
    }
  }

  /// Get earnings summary with all stats
  static Future<Map<String, dynamic>> getEarningsSummary() async {
    try {
      final response = await ApiService.get('earnings/summary');
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data'] ?? {};
      } else {
        throw Exception('Failed to load earnings summary');
      }
    } catch (e) {
      debugPrint('Get earnings summary error: $e');
      rethrow;
    }
  }

  /// Get earnings by period (weekly, monthly, yearly)
  /// 
  /// [type] - 'weekly', 'monthly', or 'yearly'
  /// [startDate] - Optional start date (ISO string)
  /// [endDate] - Optional end date (ISO string)
  static Future<Map<String, dynamic>> getEarningsByPeriod({
    required String type,
    String? startDate,
    String? endDate,
  }) async {
    try {
      String endpoint = 'earnings/period?type=$type';
      if (startDate != null) endpoint += '&startDate=$startDate';
      if (endDate != null) endpoint += '&endDate=$endDate';

      final response = await ApiService.get(endpoint);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data'] ?? {};
      } else {
        throw Exception('Failed to load earnings by period');
      }
    } catch (e) {
      debugPrint('Get earnings by period error: $e');
      rethrow;
    }
  }

  /// Get earnings history/transactions
  /// 
  /// [page] - Page number (default: 1)
  /// [limit] - Items per page (default: 20)
  /// [status] - Filter by status: 'pending', 'confirmed', 'paid', 'cancelled'
  /// [startDate] - Optional start date filter
  /// [endDate] - Optional end date filter
  static Future<Map<String, dynamic>> getEarningsHistory({
    int page = 1,
    int limit = 20,
    String? status,
    String? startDate,
    String? endDate,
  }) async {
    try {
      String endpoint = 'earnings/history?page=$page&limit=$limit';
      if (status != null) endpoint += '&status=$status';
      if (startDate != null) endpoint += '&startDate=$startDate';
      if (endDate != null) endpoint += '&endDate=$endDate';

      final response = await ApiService.get(endpoint);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data'] ?? {};
      } else {
        throw Exception('Failed to load earnings history');
      }
    } catch (e) {
      debugPrint('Get earnings history error: $e');
      rethrow;
    }
  }

  /// Create earning record (internal use - called when session completed)
  static Future<Map<String, dynamic>> createEarning({
    required String sessionId,
    String? bookingId,
    String? playerId,
    required double amount,
    required String sessionTitle,
    required String sessionDate,
    String sessionType = 'one-on-one',
  }) async {
    try {
      final response = await ApiService.post(
        'earnings',
        {
          'sessionId': sessionId,
          if (bookingId != null) 'bookingId': bookingId,
          if (playerId != null) 'playerId': playerId,
          'amount': amount,
          'sessionTitle': sessionTitle,
          'sessionDate': sessionDate,
          'sessionType': sessionType,
        },
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data'] ?? {};
      } else {
        throw Exception('Failed to create earning');
      }
    } catch (e) {
      debugPrint('Create earning error: $e');
      rethrow;
    }
  }

  /// Request cash out (MVP: placeholder)
  static Future<Map<String, dynamic>> requestCashOut({
    required double amount,
  }) async {
    try {
      final response = await ApiService.post(
        'earnings/cashout',
        {
          'amount': amount,
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to request cash out');
      }
    } catch (e) {
      debugPrint('Cash out request error: $e');
      rethrow;
    }
  }

  /// Helper method to format currency
  static String formatCurrency(double amount, {String currency = 'USD'}) {
    final symbol = _getCurrencySymbol(currency);
    return '$symbol${amount.toStringAsFixed(2)}';
  }

  /// Get currency symbol
  static String _getCurrencySymbol(String currency) {
    switch (currency.toUpperCase()) {
      case 'USD':
        return '\$';
      case 'GBP':
        return '£';
      case 'EUR':
        return '€';
      case 'INR':
        return '₹';
      case 'AUD':
        return 'A\$';
      default:
        return '\$';
    }
  }

  /// Calculate percentage with sign
  static String formatPercentageChange(double percentage) {
    final sign = percentage >= 0 ? '+' : '';
    return '$sign${percentage.toStringAsFixed(1)}%';
  }
}
