import 'dart:convert';
import 'api_service.dart';

class ReviewService {
  // Create a review
  static Future<Map<String, dynamic>> createReview({
    required String sessionId,
    required String coachId,
    required double rating,
    required String comment,
  }) async {
    try {
      final response = await ApiService.post('reviews', {
        'sessionId': sessionId,
        'coachId': coachId,
        'rating': rating,
        'comment': comment,
      });

      final data = json.decode(response.body);

      if (response.statusCode == 201) {
        return data['data'];
      } else {
        throw Exception(data['message'] ?? 'Failed to create review');
      }
    } catch (e) {
      rethrow;
    }
  }

  // Get reviews for a coach
  static Future<Map<String, dynamic>> getCoachReviews(
    String coachId, {
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final response = await ApiService.get(
        'reviews/coach/$coachId?page=$page&limit=$limit',
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        return data; // Returns { results, total, page, pages, data: [] }
      } else {
        throw Exception(data['message'] ?? 'Failed to fetch reviews');
      }
    } catch (e) {
      rethrow;
    }
  }
}
