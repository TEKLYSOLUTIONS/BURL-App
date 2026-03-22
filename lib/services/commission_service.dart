import 'dart:convert';
import 'api_service.dart';

/// Model representing a commission calculation result from the backend.
class CommissionResult {
  final double sessionFee;
  final double commissionAmount;
  final double commissionRate;
  final double total;
  final String appliedRule; // 'global', 'sport-specific', or 'user-override'

  CommissionResult({
    required this.sessionFee,
    required this.commissionAmount,
    required this.commissionRate,
    required this.total,
    required this.appliedRule,
  });

  /// Convenience: label shown in UI price breakdown
  String get label => 'Platform Fee (${commissionRate.toStringAsFixed(1)}%)';

  factory CommissionResult.fromFallback(double fee, {double rate = 12.0}) {
    final amount = (fee * rate) / 100;
    return CommissionResult(
      sessionFee: fee,
      commissionAmount: amount,
      commissionRate: rate,
      total: fee + amount,
      appliedRule: 'global',
    );
  }
}

class CommissionService {
  /// Fetch the current global commission settings (rate %).
  /// Returns globalRate as a double (e.g. 12.0 for 12%).
  static Future<double> getGlobalRate() async {
    try {
      final response = await ApiService.get('commission/settings');
      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        if (body['success'] == true && body['data'] != null) {
          return (body['data']['globalRate'] as num?)?.toDouble() ?? 12.0;
        }
      }
    } catch (e) {
      // fallback silently
    }
    return 12.0;
  }

  /// Calculate commission for a given session fee.
  /// [sessionFee] – the raw fee charged by the coach.
  /// [sportName]  – optional sport name; passed to backend for sport-specific rates.
  ///
  /// Returns a [CommissionResult] with all computed values.
  static Future<CommissionResult> calculate(
    double sessionFee, {
    String? sportName,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'sessionFee': sessionFee.toString(),
        if (sportName != null && sportName.isNotEmpty) 'sportName': sportName,
      };

      final response = await ApiService.get(
        'commission/calculate',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        if (body['success'] == true && body['data'] != null) {
          final data = body['data'] as Map<String, dynamic>;
          return CommissionResult(
            sessionFee: (data['sessionFee'] as num?)?.toDouble() ?? sessionFee,
            commissionAmount:
                (data['commissionAmount'] as num?)?.toDouble() ?? 0.0,
            commissionRate:
                (data['commissionRate'] as num?)?.toDouble() ?? 12.0,
            total: (data['total'] as num?)?.toDouble() ?? sessionFee,
            appliedRule:
                data['appliedRule']?.toString() ?? 'global',
          );
        }
      }
    } catch (e) {
      // Fallback to local calculation using default 12%
    }
    return CommissionResult.fromFallback(sessionFee);
  }
}
