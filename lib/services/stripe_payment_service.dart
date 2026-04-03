import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/api_config.dart';

class StripePaymentService {
  static final StripePaymentService _instance = StripePaymentService._();
  factory StripePaymentService() => _instance;
  StripePaymentService._();

  // ── Auth Headers ──────────────────────────────────────────────────────────

  Future<Map<String, String>> _headers() async {
    String? token;
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) token = await user.getIdToken();
    } catch (_) {}

    if (token == null) {
      final secureStorage = const FlutterSecureStorage();
      token = await secureStorage.read(key: 'auth_token');
    }

    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ── Customer ──────────────────────────────────────────────────────────────

  /// Ensures a Stripe Customer exists for the current user.
  Future<String?> ensureCustomer() async {
    final res = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/payments/customer/create-or-get'),
      headers: await _headers(),
    );
    if (res.statusCode == 200) {
      final data = json.decode(res.body);
      return data['customerId'] as String?;
    }
    return null;
  }

  // ── Saved Cards ───────────────────────────────────────────────────────────

  /// Opens Stripe Payment Sheet to add and save a new card.
  /// Returns true on success.
  Future<bool> addCard(BuildContext context) async {
    try {
      final res = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/payments/setup-intent'),
        headers: await _headers(),
      );
      if (res.statusCode != 200) {
        debugPrint('Failed to get setup-intent: ${res.statusCode} - ${res.body}');
        return false;
      }

      final data = json.decode(res.body);
      final clientSecret = data['clientSecret'] as String;
      final customerId = data['customerId'] as String;

      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          setupIntentClientSecret: clientSecret,
          customerId: customerId,
          merchantDisplayName: 'Cricket Coaching',
          style: ThemeMode.light,
        ),
      );

      await Stripe.instance.presentPaymentSheet();
      return true;
    } on StripeException catch (e) {
      debugPrint('Stripe sheet cancelled or failed: $e');
      return false;
    } catch (e) {
      debugPrint('Error in StripePaymentService.addCard: $e');
      rethrow;
    }
  }

  /// Returns the list of saved cards for this user.
  Future<List<Map<String, dynamic>>> listCards() async {
    final res = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/payments/payment-methods'),
      headers: await _headers(),
    );
    if (res.statusCode == 200) {
      final data = json.decode(res.body);
      final methods = data['paymentMethods'] as List;
      return methods.map((m) => m as Map<String, dynamic>).toList();
    }
    return [];
  }

  /// Deletes a saved card by its PaymentMethod ID.
  Future<bool> deleteCard(String pmId) async {
    final res = await http.delete(
      Uri.parse('${ApiConfig.baseUrl}/payments/payment-methods/$pmId'),
      headers: await _headers(),
    );
    return res.statusCode == 200;
  }

  // ── Booking Charge ────────────────────────────────────────────────────────

  /// Charges a booking. Returns the PaymentIntent ID on success, or throws.
  /// [amountCents] must already be in the smallest currency unit (e.g. cents).
  Future<String> chargeBooking({
    required int amountCents,
    required String paymentMethodId,
    required String coachId,
    String currency = 'usd',
    String description = 'Session Booking',
  }) async {
    final res = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/payments/charge-booking'),
      headers: await _headers(),
      body: json.encode({
        'amount': amountCents,
        'currency': currency,
        'paymentMethodId': paymentMethodId,
        'coachId': coachId,
        'bookingDescription': description,
      }),
    );

    final data = json.decode(res.body);
    if (res.statusCode == 200 && data['success'] == true) {
      return data['paymentIntentId'] as String;
    }
    throw Exception(data['message'] ?? 'Payment failed');
  }

  // ── Subscriptions ─────────────────────────────────────────────────────────

  /// Creates a Stripe Subscription for a coach plan.
  /// [priceId] is the Stripe Price ID (monthly or annual).
  /// Returns { subscriptionId, status, clientSecret? }.
  Future<Map<String, dynamic>> subscribeCoach({
    required String priceId,
    required String paymentMethodId,
    int trialDays = 0,
  }) async {
    final res = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/payments/subscription/create'),
      headers: await _headers(),
      body: json.encode({
        'priceId': priceId,
        'paymentMethodId': paymentMethodId,
        'trialDays': trialDays,
      }),
    );

    final data = json.decode(res.body);
    if (res.statusCode == 200 && data['success'] == true) {
      return data as Map<String, dynamic>;
    }
    throw Exception(data['message'] ?? 'Subscription failed');
  }

  /// Cancels the coach's subscription at period end.
  Future<bool> cancelSubscription() async {
    final res = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/payments/subscription/cancel'),
      headers: await _headers(),
    );
    return res.statusCode == 200;
  }

  /// Returns the current subscription status for the coach.
  Future<Map<String, dynamic>?> getSubscriptionStatus() async {
    final res = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/payments/subscription/status'),
      headers: await _headers(),
    );
    if (res.statusCode == 200) return json.decode(res.body) as Map<String, dynamic>;
    return null;
  }

  // ── Stripe Connect ────────────────────────────────────────────────────────

  /// Returns the Stripe Connect onboarding URL for a coach.
  Future<String?> getConnectOnboardingUrl() async {
    final res = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/payments/connect/onboard'),
      headers: await _headers(),
    );
    if (res.statusCode == 200) {
      return json.decode(res.body)['url'] as String?;
    }
    return null;
  }

  /// Returns the coach's Connect account status.
  Future<Map<String, dynamic>?> getConnectStatus() async {
    final res = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/payments/connect/status'),
      headers: await _headers(),
    );
    if (res.statusCode == 200) return json.decode(res.body) as Map<String, dynamic>;
    return null;
  }
}
