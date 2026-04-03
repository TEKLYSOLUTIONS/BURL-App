import 'dart:convert';
import 'api_service.dart';

/// Service for managing booking-related API calls
class _BookingCacheEntry {
  final Map<String, dynamic> data;
  final DateTime timestamp;

  _BookingCacheEntry({required this.data, required this.timestamp});
}

class BookingService {
  // ─── Cache ───────────────────────────────────────────────────────────────
  static final Map<String, _BookingCacheEntry> _playerBookingsCache = {};
  static final Map<String, _BookingCacheEntry> _coachBookingsCache = {};
  static const _cacheTtl = Duration(minutes: 5);

  static void invalidatePlayerBookingsCache() {
    _playerBookingsCache.clear();
  }

  static void invalidateCoachBookingsCache() {
    _coachBookingsCache.clear();
  }

  static String _buildCacheKey(String type, int limit, int page) {
    return '${type}_${limit}_$page';
  }
  // ─────────────────────────────────────────────────────────────────────────
  /// Create a new booking
  ///
  /// [sessionId] - ID of the session to book
  /// [occurrenceDate] - ISO 8601 string of the specific occurrence date/time
  /// [paymentMethod] - Payment method ('card', 'apple_pay', 'google_pay')
  /// [promoCode] - Optional promo code for discount
  static Future<Map<String, dynamic>> createBooking({
    required String sessionId,
    String? occurrenceDate,
    List<String>? occurrenceDates,
    required String paymentMethod,
    String? paymentIntentId,
    String? promoCode,
    String? playerId,
  }) async {
    try {
      final response = await ApiService.post('bookings', {
        'sessionId': sessionId,
        if (occurrenceDate != null) 'occurrenceDate': occurrenceDate,
        if (occurrenceDates != null) 'occurrenceDates': occurrenceDates,
        'paymentMethod': paymentMethod,
        if (paymentIntentId != null) 'paymentIntentId': paymentIntentId,
        if (promoCode != null && promoCode.isNotEmpty) 'promoCode': promoCode,
        if (playerId != null && playerId.isNotEmpty) 'playerId': playerId,
      });

      final data = json.decode(response.body);

      if (response.statusCode == 201) {
        invalidatePlayerBookingsCache();
        invalidateCoachBookingsCache();
        return data['booking'];
      } else {
        throw Exception(data['message'] ?? 'Failed to create booking');
      }
    } catch (e) {
      throw Exception('Error creating booking: $e');
    }
  }

  static Future<Map<String, dynamic>> createPrivateBooking({
    required String coachId,
    required DateTime startTime,
    int durationMinutes = 60,
    required String paymentMethod,
    String? paymentIntentId,
    String? promoCode,
    List<String>? playerIds,
  }) async {
    try {
      final response = await ApiService.post('bookings/private', {
        'coachId': coachId,
        'startTime': startTime.toUtc().toIso8601String(),
        'durationMinutes': durationMinutes,
        'paymentMethod': paymentMethod,
        if (paymentIntentId != null) 'paymentIntentId': paymentIntentId,
        if (promoCode != null && promoCode.isNotEmpty) 'promoCode': promoCode,
        if (playerIds != null && playerIds.isNotEmpty) 'playerIds': playerIds,
      });

      final data = json.decode(response.body);

      if (response.statusCode == 201) {
        invalidatePlayerBookingsCache();
        invalidateCoachBookingsCache();
        return data['bookings'] != null &&
                data['bookings'] is List &&
                (data['bookings'] as List).isNotEmpty
            ? data['bookings'][
                0] // Return first booking for compatibility, or change return type?
            : data['booking'] ?? {}; // Fallback
      } else {
        throw Exception(data['message'] ?? 'Failed to create private booking');
      }
    } catch (e) {
      throw Exception('Error creating private booking: $e');
    }
  }

  /// Get player's bookings
  ///
  /// [type] - 'upcoming', 'past', or 'all'
  /// [limit] - Number of bookings to fetch (default: 10)
  /// [page] - Page number for pagination (default: 1)
  static Future<Map<String, dynamic>> getPlayerBookings({
    String type = 'all',
    int limit = 10,
    int page = 1,
  }) async {
    final cacheKey = _buildCacheKey(type, limit, page);
    final cached = _playerBookingsCache[cacheKey];
    if (cached != null &&
        DateTime.now().difference(cached.timestamp) < _cacheTtl) {
      return Map<String, dynamic>.from(cached.data);
    }

    try {
      final response = await ApiService.get(
        'bookings?type=$type&limit=$limit&page=$page',
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        final result = {
          'bookings': data['bookings'] as List<dynamic>,
          'pagination': data['pagination'],
        };
        _playerBookingsCache[cacheKey] = _BookingCacheEntry(
          data: result,
          timestamp: DateTime.now(),
        );
        return result;
      } else {
        throw Exception(data['message'] ?? 'Failed to fetch bookings');
      }
    } catch (e) {
      throw Exception('Error fetching bookings: $e');
    }
  }

  /// Get a specific booking by ID
  ///
  /// [bookingId] - ID of the booking to fetch
  static Future<Map<String, dynamic>> getBookingById(String bookingId) async {
    try {
      final response = await ApiService.get('bookings/$bookingId');

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        return data['booking'];
      } else if (response.statusCode == 404) {
        throw Exception('Booking not found');
      } else {
        throw Exception(data['message'] ?? 'Failed to fetch booking');
      }
    } catch (e) {
      throw Exception('Error fetching booking: $e');
    }
  }

  /// Cancel a booking
  ///
  /// [bookingId] - ID of the booking to cancel
  /// [reason] - Optional cancellation reason
  static Future<bool> cancelBooking(String bookingId, {String? reason}) async {
    try {
      final response = await ApiService.put('bookings/$bookingId/cancel', {
        if (reason != null && reason.isNotEmpty) 'reason': reason,
      });
      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        invalidatePlayerBookingsCache();
        invalidateCoachBookingsCache();
        return true;
      } else {
        throw Exception(data['message'] ?? 'Failed to cancel booking');
      }
    } catch (e) {
      throw Exception('Error cancelling booking: $e');
    }
  }

  /// Validate a promo code
  ///
  /// Returns a map with 'valid' bool; on success also 'code', 'discountType',
  /// 'discountValue', 'minimumPrice'; on failure 'message'.
  static Future<Map<String, dynamic>> validatePromoCode(String code) async {
    try {
      final response = await ApiService.post('bookings/validate-promo', {
        'code': code.toUpperCase(), // backend key is 'code', not 'promoCode'
      });

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final promoData =
            data['data']['promoCode'] as Map<String, dynamic>? ?? {};
        final discountType =
            promoData['discountType']?.toString() ?? 'fixed';
        final discountValue =
            (promoData['discountValue'] as num?)?.toDouble() ?? 0.0;
        return {
          'valid': true,
          'code': promoData['code']?.toString() ?? code.toUpperCase(),
          'discountType': discountType,
          'discountValue': discountValue,
          'minimumPrice':
              (promoData['minimumPrice'] as num?)?.toDouble() ?? 0.0,
        };
      } else {
        return {
          'valid': false,
          'message': data['message']?.toString() ?? 'Invalid promo code',
        };
      }
    } catch (e) {
      return {
        'valid': false,
        'message': 'Error validating promo code',
      };
    }
  }

  /// Get coach's bookings
  ///
  /// [type] - 'upcoming', 'past', or 'cancelled'
  /// [limit] - Number of bookings to fetch (default: 20)
  /// [page] - Page number for pagination (default: 1)
  static Future<Map<String, dynamic>> getCoachBookings({
    String type = 'upcoming',
    int limit = 20,
    int page = 1,
  }) async {
    final cacheKey = _buildCacheKey(type, limit, page);
    final cached = _coachBookingsCache[cacheKey];
    if (cached != null &&
        DateTime.now().difference(cached.timestamp) < _cacheTtl) {
      return Map<String, dynamic>.from(cached.data);
    }

    try {
      final response = await ApiService.get(
        'bookings/coach?type=$type&limit=$limit&page=$page',
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        final result = {
          'bookings': data['bookings'] as List<dynamic>,
          'pagination': data['pagination'],
        };
        _coachBookingsCache[cacheKey] = _BookingCacheEntry(
          data: result,
          timestamp: DateTime.now(),
        );
        return result;
      } else {
        throw Exception(data['message'] ?? 'Failed to fetch coach bookings');
      }
    } catch (e) {
      throw Exception('Error fetching coach bookings: $e');
    }
  }

  /// Update booking status (for Coach)
  ///
  /// [bookingId] - ID of the booking
  /// [status] - 'confirmed', 'cancelled', or 'declined'
  /// [reason] - Optional reason for cancellation/declining
  static Future<Map<String, dynamic>> updateBookingStatus(
    String bookingId,
    String status, {
    String? reason,
  }) async {
    try {
      final response = await ApiService.put('bookings/$bookingId/status', {
        'status': status,
        if (reason != null && reason.isNotEmpty) 'reason': reason,
      });

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        invalidatePlayerBookingsCache();
        invalidateCoachBookingsCache();
        return data['booking'];
      } else {
        throw Exception(data['message'] ?? 'Failed to update booking status');
      }
    } catch (e) {
      throw Exception('Error updating booking status: $e');
    }
  }
}
