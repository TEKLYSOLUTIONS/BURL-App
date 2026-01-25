import 'dart:convert';
import 'api_service.dart';

/// Service for managing booking-related API calls
class BookingService {
  /// Create a new booking
  ///
  /// [sessionId] - ID of the session to book
  /// [occurrenceDate] - ISO 8601 string of the specific occurrence date/time
  /// [paymentMethod] - Payment method ('card', 'apple_pay', 'google_pay')
  /// [promoCode] - Optional promo code for discount
  static Future<Map<String, dynamic>> createBooking({
    required String sessionId,
    required String occurrenceDate,
    required String paymentMethod,
    String? promoCode,
  }) async {
    try {
      final response = await ApiService.post('bookings', {
        'sessionId': sessionId,
        'occurrenceDate': occurrenceDate,
        'paymentMethod': paymentMethod,
        if (promoCode != null && promoCode.isNotEmpty) 'promoCode': promoCode,
      });

      final data = json.decode(response.body);

      if (response.statusCode == 201) {
        return data['booking'];
      } else {
        throw Exception(data['message'] ?? 'Failed to create booking');
      }
    } catch (e) {
      throw Exception('Error creating booking: $e');
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
    try {
      final response = await ApiService.get(
        'bookings?type=$type&limit=$limit&page=$page',
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        return {
          'bookings': data['bookings'] as List<dynamic>,
          'pagination': data['pagination'],
        };
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
  /// [code] - Promo code to validate
  /// Returns a map with 'valid', 'discount', and 'code' if valid
  static Future<Map<String, dynamic>> validatePromoCode(String code) async {
    try {
      final response = await ApiService.post('bookings/validate-promo', {
        'code': code,
      });

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        return {
          'valid': data['valid'],
          'discount': data['discount'],
          'code': data['code'],
          'type': data['type'],
        };
      } else {
        // Return invalid response
        return {
          'valid': false,
          'discount': 0.0,
          'message': data['message'] ?? 'Invalid promo code',
        };
      }
    } catch (e) {
      return {
        'valid': false,
        'discount': 0.0,
        'message': 'Error validating promo code',
      };
    }
  }
}
