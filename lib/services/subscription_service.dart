import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/api_config.dart';
import '../models/subscription_plan.dart';

class PromoCodeValidation {
  final bool valid;
  final String id;
  final String code;
  final String discountType; // 'percentage' or 'fixed'
  final double discountValue;
  final double minimumPrice;
  final String category; // 'subscription' or 'commission'

  PromoCodeValidation({
    required this.valid,
    required this.id,
    required this.code,
    required this.discountType,
    required this.discountValue,
    required this.minimumPrice,
    required this.category,
  });

  factory PromoCodeValidation.fromJson(Map<String, dynamic> json) {
    final promoData = json['promoCode'];
    return PromoCodeValidation(
      valid: json['valid'] ?? false,
      id: promoData['id'] ?? '',
      code: promoData['code'] ?? '',
      discountType: promoData['discountType'] ?? 'percentage',
      discountValue: (promoData['discountValue'] ?? 0).toDouble(),
      minimumPrice: (promoData['minimumPrice'] ?? 0).toDouble(),
      category: promoData['category'] ?? 'subscription',
    );
  }

  double calculateDiscount(double originalPrice) {
    if (discountType == 'percentage') {
      return originalPrice * (discountValue / 100);
    } else {
      return discountValue;
    }
  }

  double applyDiscount(double originalPrice) {
    final discount = calculateDiscount(originalPrice);
    final finalPrice = originalPrice - discount;
    return finalPrice > 0 ? finalPrice : 0;
  }
}

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

  Future<void> activateSubscription({
    required String planId,
    required bool isAnnual,
    String? paymentMethodId,
  }) async {
    try {
      final secureStorage = const FlutterSecureStorage();
      final token = await secureStorage.read(key: 'auth_token');

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/subscriptions/activate'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'planId': planId,
          'isAnnual': isAnnual,
          if (paymentMethodId != null) 'paymentMethodId': paymentMethodId,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode != 200 || data['success'] != true) {
        throw Exception(data['message'] ?? 'Failed to activate subscription');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<PromoCodeValidation> validatePromoCode({
    required String code,
    String? planId,
    String? userId,
  }) async {
    try {
      final secureStorage = const FlutterSecureStorage();
      final token = await secureStorage.read(key: 'auth_token');
      
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/bookings/validate-promo'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'code': code,
          if (planId != null) 'planId': planId,
          if (userId != null) 'userId': userId,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return PromoCodeValidation.fromJson(data['data']);
      } else {
        throw Exception(data['message'] ?? 'Invalid promo code');
      }
    } catch (e) {
      rethrow;
    }
  }
}
