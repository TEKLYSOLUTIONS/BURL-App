import 'dart:convert';

import 'api_service.dart';

class SearchService {
  // Search coaches
  Future<Map<String, dynamic>> searchCoaches({
    String? query,
    String? specialization,
    double? minRating,
    String? location,
    int page = 1,
    int limit = 10,
  }) async {
    try {
      // Build query parameters
      final Map<String, dynamic> queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
      };

      if (query != null && query.isNotEmpty) {
        queryParams['query'] = query;
      }
      if (specialization != null && specialization.isNotEmpty) {
        queryParams['specialization'] = specialization;
      }
      if (minRating != null) {
        queryParams['minRating'] = minRating.toString();
      }
      if (location != null && location.isNotEmpty) {
        queryParams['location'] = location;
      }

      final response = await ApiService.get(
        'search/coaches',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to search coaches: ${response.body}');
      }
    } catch (e) {
      rethrow;
    }
  }

  // Search sessions
  Future<Map<String, dynamic>> searchSessions({
    String? query,
    String? location,
    DateTime? startDate,
    DateTime? endDate,
    int page = 1,
    int limit = 10,
  }) async {
    try {
      // Build query parameters
      final Map<String, dynamic> queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
      };

      if (query != null && query.isNotEmpty) {
        queryParams['query'] = query;
      }
      if (location != null && location.isNotEmpty) {
        queryParams['location'] = location;
      }
      if (startDate != null) {
        queryParams['startDate'] = startDate.toIso8601String();
      }
      if (endDate != null) {
        queryParams['endDate'] = endDate.toIso8601String();
      }

      final response = await ApiService.get(
        'search/sessions',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to search sessions: ${response.body}');
      }
    } catch (e) {
      rethrow;
    }
  }

  // Search all (coaches and sessions)
  Future<Map<String, dynamic>> searchAll({String? query, int limit = 5}) async {
    try {
      // Build query parameters
      final Map<String, dynamic> queryParams = {'limit': limit.toString()};

      if (query != null && query.isNotEmpty) {
        queryParams['query'] = query;
      }

      final response = await ApiService.get(
        'search/all',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to search: ${response.body}');
      }
    } catch (e) {
      rethrow;
    }
  }

  // Get coach details by ID
  Future<Map<String, dynamic>> getCoachDetails(String coachId) async {
    try {
      final response = await ApiService.get('search/coaches/$coachId');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load coach details: ${response.body}');
      }
    } catch (e) {
      rethrow;
    }
  }
}
