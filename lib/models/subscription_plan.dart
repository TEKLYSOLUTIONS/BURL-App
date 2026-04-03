class SubscriptionFeature {
  final String name;
  final bool included;
  final bool highlight;

  SubscriptionFeature({
    required this.name,
    required this.included,
    this.highlight = false,
  });

  factory SubscriptionFeature.fromJson(Map<String, dynamic> json) {
    return SubscriptionFeature(
      name: json['name'] as String,
      included: json['included'] as bool? ?? true,
      highlight: json['highlight'] as bool? ?? false,
    );
  }
}

class SubscriptionPlan {
  final String id;
  final String planId;
  final String name;
  final String? description;
  final int price;
  final String currency;
  final String interval;
  final String tier;
  final int trialPeriodDays;
  final List<SubscriptionFeature> features;
  final bool isPopular;
  // Stripe Price IDs (set in Stripe dashboard; null if not configured yet)
  final String? stripePriceIdMonthly;
  final String? stripePriceIdAnnual;

  SubscriptionPlan({
    required this.id,
    required this.planId,
    required this.name,
    this.description,
    required this.price,
    required this.currency,
    required this.interval,
    required this.tier,
    required this.trialPeriodDays,
    required this.features,
    required this.isPopular,
    this.stripePriceIdMonthly,
    this.stripePriceIdAnnual,
  });

  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) {
    return SubscriptionPlan(
      id: json['id'] as String,
      planId: json['planId'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      price: (json['price'] as num).toInt(),
      currency: json['currency'] as String,
      interval: json['interval'] as String,
      tier: json['tier'] as String,
      trialPeriodDays: json['trialPeriodDays'] as int? ?? 0,
      features:
          (json['features'] as List<dynamic>?)
              ?.map(
                (e) => SubscriptionFeature.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          [],
      isPopular: json['isPopular'] as bool? ?? false,
      stripePriceIdMonthly: json['stripePriceIdMonthly'] as String?,
      stripePriceIdAnnual: json['stripePriceIdAnnual'] as String?,
    );
  }

  bool get isPro => tier == 'Premium' || tier == 'Enterprise';
}
