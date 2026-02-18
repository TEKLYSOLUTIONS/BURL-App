import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/subscription_plan.dart';

class SubscriptionService {
  Future<List<SubscriptionPlan>> getPlans() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/subscriptions/plans'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final List<dynamic> plansJson = data['data'];
          return plansJson
              .map((json) => SubscriptionPlan.fromJson(json))
              .toList();
        } else {
          throw Exception(data['message'] ?? 'Failed to load plans');
        }
      } else {
        throw Exception('Failed to load plans: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching plans: $e');
    }
  }
}
