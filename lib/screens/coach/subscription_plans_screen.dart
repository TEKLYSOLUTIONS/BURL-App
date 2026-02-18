import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../config/palette.dart';
import '../../widgets/headers/coach_app_bar.dart';
import '../../widgets/notification_button.dart';

import '../../models/subscription_plan.dart';
import '../../services/subscription_service.dart';

class SubscriptionPlansScreen extends StatefulWidget {
  const SubscriptionPlansScreen({super.key});

  @override
  State<SubscriptionPlansScreen> createState() =>
      _SubscriptionPlansScreenState();
}

class _SubscriptionPlansScreenState extends State<SubscriptionPlansScreen> {
  bool _isAnnual = false;
  final _subscriptionService = SubscriptionService();
  bool _isLoading = true;
  List<SubscriptionPlan> _plans = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchPlans();
  }

  Future<void> _fetchPlans() async {
    try {
      final plans = await _subscriptionService.getPlans();
      if (mounted) {
        setState(() {
          _plans = plans;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Filter plans based on interval (assuming backend returns both 'month' and 'year')
    // OR if backend returns a single plan object with price/interval, we might need to handle it differently.
    // For now, let's assume we filter by the selected interval.
    // However, usually plans are grouped (e.g. Pro Monthly vs Pro Annual).
    // Let's filter by matching interval.
    final displayedPlans = _plans.where((p) {
      final planInterval = p.interval.toLowerCase();
      return _isAnnual ? planInterval == 'year' : planInterval == 'month';
    }).toList();

    // Sort by price to ensure order (Free -> Pro)
    displayedPlans.sort((a, b) => a.price.compareTo(b.price));

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          CoachAppBar(
            backgroundColor: AppPalette.navyPrimary,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (context.canPop())
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => context.pop(),
                  )
                else
                  const SizedBox(width: 40),
                Expanded(
                  child: Text(
                    'Upgrade Your Plan',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                NotificationButton(
                  iconColor: Colors.white,
                  backgroundColor: Colors.white.withValues(alpha: 0.1),
                  onTap: () => context.push('/coach/notifications'),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Error loading plans',
                              style: GoogleFonts.inter(fontSize: 18),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _error!,
                              style: GoogleFonts.inter(fontSize: 14, color: Colors.red),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _fetchPlans,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 16),

                    Text(
                      'Choose the Right Plan for You',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ).animate().fadeIn().slideY(begin: 0.1),

                    const SizedBox(height: 12),

                    Text(
                      'Unlock advanced features to scale your coaching business.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ).animate().fadeIn().slideY(begin: 0.1, delay: 100.ms),

                    const SizedBox(height: 32),

                    // Monthly / Annual Toggle
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: Theme.of(
                            context,
                          ).dividerColor.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildToggleOption('Monthly', !_isAnnual),
                          _buildToggleOption('Annual (Save 20%)', _isAnnual),
                        ],
                      ),
                    ).animate().fadeIn(delay: 200.ms),

                    const SizedBox(height: 40),

                    // Dynamic Plans
                    if (displayedPlans.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Text(
                          "No plans available for this interval.",
                          style: GoogleFonts.inter(color: Colors.grey),
                        ),
                      ),

                    ...displayedPlans.map((plan) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 24.0),
                        child: _buildPlanCard(
                          title: plan.name,
                          price: plan.price,
                          description: plan.description ?? '',
                          features: plan.features,
                          isPro:
                              plan.isPro, // You might want to adjust this logic
                          isAnnual: plan.interval == 'year',
                          isPopular: plan.isPopular,
                        ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2),
                      );
                    }),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleOption(String text, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isAnnual = text.contains('Annual');
        });
      },
      child: AnimatedContainer(
        duration: 200.ms,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Colors.transparent,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Text(
          text,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            color: isSelected
                ? Theme.of(context).colorScheme.onPrimary
                : Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ),
    );
  }

  Widget _buildPlanCard({
    required String title,
    required int price,
    required String description,
    required List<SubscriptionFeature> features,
    required bool isPro,
    required bool isPopular,
    bool isAnnual = false,
  }) {
    return Stack(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isPro
                  ? Theme.of(context).colorScheme.secondary
                  : Theme.of(context).dividerColor.withValues(alpha: 0.5),
              width: isPro ? 2 : 1,
            ),
            boxShadow: isPro
                ? [
                    BoxShadow(
                      color: Theme.of(
                        context,
                      ).colorScheme.secondary.withValues(alpha: 0.2),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Theme.of(
                        context,
                      ).shadowColor.withValues(alpha: 0.05),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isPro) const SizedBox(height: 12), // Space for badge
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: GoogleFonts.inter(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.6),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '\$$price',
                    style: GoogleFonts.inter(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    isAnnual ? '/year' : '/month',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.6),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Divider(color: Theme.of(context).dividerColor),
              const SizedBox(height: 24),
              ...features.map(
                (feature) => _buildFeatureItem(feature.name, feature.included),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isPro
                        ? Theme.of(context).colorScheme.secondary
                        : Theme.of(context).dividerColor.withValues(alpha: 0.2),
                    foregroundColor: isPro
                        ? Colors.white
                        : Theme.of(context).colorScheme.onSurface,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: isPro ? 4 : 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    isPro ? 'Get Started' : 'Current Plan',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (isPopular)
          Positioned(
            top: -12,
            right: 24,
            child:
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondary,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(
                          context,
                        ).colorScheme.secondary.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Text(
                    'MOST POPULAR',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ).animate().slideY(
                  begin: -0.5,
                  end: 1.5,
                  duration: 600.ms,
                  curve: Curves.elasticOut,
                ), // Drop animation
          ),
      ],
    );
  }

  Widget _buildFeatureItem(String text, bool isHighlighed) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isHighlighed
                  ? AppPalette.successGreen.withValues(alpha: 0.1)
                  : Theme.of(context).dividerColor.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check,
              size: 14,
              color: isHighlighed
                  ? AppPalette.successGreen
                  : Theme.of(context).disabledColor,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            text,
            style: GoogleFonts.inter(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
