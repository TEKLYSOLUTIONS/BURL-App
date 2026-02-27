import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../config/palette.dart';

import '../../models/subscription_plan.dart';
import '../../services/subscription_service.dart';
import '../../services/profile_service.dart';
import '../../utils/currency_helper.dart';
import 'subscription_payment_screen.dart';

class ProUpgradeScreen extends StatefulWidget {
  const ProUpgradeScreen({super.key});

  @override
  State<ProUpgradeScreen> createState() => _ProUpgradeScreenState();
}

class _ProUpgradeScreenState extends State<ProUpgradeScreen> {
  bool _isLoading = true; // Start loading true
  final _subscriptionService = SubscriptionService();
  List<SubscriptionPlan> _plans = [];
  String? _error;
  final PageController _pageController = PageController();
  int _currentPlanIndex = 0;
  String _userCurrency =
      CurrencyHelper.defaultCurrency; // User's preferred currency
  String? _userLocation;
  bool _isAnnualSelected =
      true; // Track monthly vs annual selection (default to annual for discount)
  String? _userId;
  String _currentUserPlan = 'free'; // Actual plan from user's profile
  String _subscriptionStatus = 'inactive'; // Actual subscription status

  @override
  void initState() {
    super.initState();
    _fetchUserCurrency();
    _fetchPlans();
  }

  // Navigate to the payment screen for the currently selected plan
  void _goToPayment() {
    final currentPlan =
        _proPlans.isNotEmpty && _currentPlanIndex < _proPlans.length
            ? _proPlans[_currentPlanIndex]
            : null;
    if (currentPlan == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SubscriptionPaymentScreen(
          plan: currentPlan,
          isAnnual: _isAnnualSelected,
          currency: _userCurrency,
          userId: _userId,
        ),
      ),
    );
  }

  Future<void> _fetchUserCurrency() async {
    try {
      final profile = await ProfileService.getProfile();

      // Store userId
      _userId = profile['_id'] ?? profile['id'];

      // Try to get currency and plan info from profile
      String? currency;
      if (profile['coachProfile'] != null) {
        currency = profile['coachProfile']['currency'];
        _userLocation = profile['coachProfile']['city'];
        final planField = profile['coachProfile']['plan'] as String?;
        final sub =
            profile['coachProfile']['subscription'] as Map<String, dynamic>?;
        if (planField != null) {
          _currentUserPlan = planField;
        }
        if (sub != null) {
          _subscriptionStatus = sub['status'] as String? ?? 'inactive';
        }
      } else if (profile['playerProfile'] != null) {
        currency = profile['playerProfile']['currency'];
        _userLocation = profile['playerProfile']['city'];
      }

      // If currency not in profile, detect from location
      if (currency == null && _userLocation != null) {
        currency = CurrencyHelper.getCurrencyFromLocation(_userLocation);
      }

      if (mounted) {
        setState(() {
          _userCurrency = currency ?? CurrencyHelper.defaultCurrency;
        });
      }
    } catch (e) {
      // Use default currency if profile fetch fails
      if (mounted) {
        setState(() {
          _userCurrency = CurrencyHelper.defaultCurrency;
        });
      }
    }
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
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  List<SubscriptionPlan> get _proPlans {
    final proPlans = _plans.where((p) => p.isPro).toList();

    // Prefer plans in user's currency, but show all if none match
    final matchingCurrencyPlans = proPlans
        .where((p) => p.currency.toUpperCase() == _userCurrency.toUpperCase())
        .toList();

    if (matchingCurrencyPlans.isNotEmpty) {
      return matchingCurrencyPlans;
    }

    // If no plans match user's currency, return all pro plans
    return proPlans;
  }

  int _calculateAnnualPrice(int monthlyPrice) {
    // Calculate annual price (monthly * 12) with 20% discount
    return (monthlyPrice * 12 * 0.8).round();
  }

  int _calculateSavings(int monthlyPrice) {
    final fullAnnual = monthlyPrice * 12;
    final discountedAnnual = _calculateAnnualPrice(monthlyPrice);
    return fullAnnual - discountedAnnual;
  }

  void _handleSubscription() => _goToPayment();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildHeader(),
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
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: Colors.red,
                              ),
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 24,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Currency Info Banner
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: AppPalette.navyPrimary
                                    .withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppPalette.navyPrimary
                                      .withValues(alpha: 0.1),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    size: 18,
                                    color: AppPalette.navyPrimary,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _userLocation != null
                                          ? 'Prices shown in ${CurrencyHelper.getCurrencyName(_userCurrency)} based on your location: $_userLocation'
                                          : 'Prices shown in ${CurrencyHelper.getCurrencyName(_userCurrency)}',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: AppPalette.navyPrimary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ).animate().fadeIn(duration: 300.ms),

                            const SizedBox(height: 24),

                            // 1. Free Plan Container
                            _buildFreePlanCard()
                                .animate()
                                .fadeIn(duration: 400.ms)
                                .slideY(begin: 0.1),

                            const SizedBox(height: 24),

                            // 2. Swipeable Pro Plan Cards
                            if (_proPlans.isNotEmpty) ...[
                              SizedBox(
                                height: 620,
                                child: PageView.builder(
                                  controller: _pageController,
                                  onPageChanged: (index) {
                                    setState(() {
                                      _currentPlanIndex = index;
                                    });
                                  },
                                  itemCount: _proPlans.length,
                                  itemBuilder: (context, index) {
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8),
                                      child:
                                          _buildProPlanCard(_proPlans[index]),
                                    );
                                  },
                                ),
                              )
                                  .animate()
                                  .fadeIn(delay: 200.ms)
                                  .slideY(begin: 0.1),
                              const SizedBox(height: 16),
                              // Page Indicator
                              if (_proPlans.length > 1)
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: List.generate(
                                    _proPlans.length,
                                    (index) => Container(
                                      margin: const EdgeInsets.symmetric(
                                          horizontal: 4),
                                      width:
                                          _currentPlanIndex == index ? 24 : 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: _currentPlanIndex == index
                                            ? AppPalette.navyPrimary
                                            : Colors.grey[300],
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                  ),
                                ).animate().fadeIn(delay: 250.ms),
                            ],

                            // Show message if no premium plans
                            if (_proPlans.isEmpty)
                              Container(
                                height: 200,
                                alignment: Alignment.center,
                                child: Text(
                                  'No premium plans available',
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ),

                            const SizedBox(height: 24),

                            // 4. Trial Banner
                            if (_plans
                                .any((p) => p.isPro && p.trialPeriodDays > 0))
                              Container(
                                width: double.infinity,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                decoration: BoxDecoration(
                                  color:
                                      const Color(0xFFFF7D20), // Vibrant Orange
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.card_giftcard,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${_plans.firstWhere((p) => p.isPro && p.trialPeriodDays > 0).trialPeriodDays}-day free trial included',
                                      style: GoogleFonts.inter(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ).animate().fadeIn(delay: 300.ms),

                            if (_plans
                                .any((p) => p.isPro && p.trialPeriodDays > 0))
                              const SizedBox(height: 32),

                            // 5. Start Free Trial CTA
                            SizedBox(
                              height: 56,
                              child: ElevatedButton(
                                onPressed:
                                    _isLoading ? null : _handleSubscription,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFFF7D20),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  elevation: 4,
                                  shadowColor:
                                      Colors.orange.withValues(alpha: 0.4),
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            _isAnnualSelected
                                                ? 'Start Annual Trial'
                                                : 'Start Monthly Trial',
                                            style: GoogleFonts.inter(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          const Icon(
                                            Icons.arrow_forward,
                                            color: Colors.white,
                                          ),
                                        ],
                                      ),
                              ),
                            )
                                .animate()
                                .fadeIn(delay: 500.ms)
                                .slideY(begin: 0.2),

                            const SizedBox(height: 24),

                            Text(
                              'Recurring billing, cancel anytime.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: Colors.grey[500],
                              ),
                            ),
                            const SizedBox(height: 16),

                            Text(
                              'Have a promo code? You can apply it on the next step.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppPalette.orangeAccent,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  // --- Widgets ---

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 20,
        bottom: 24,
        left: 24,
        right: 24,
      ),
      decoration: const BoxDecoration(
        color: AppPalette.navyPrimary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          Text(
            'Upgrade to Pro',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 24), // Spacer
        ],
      ),
    );
  }

  Widget _buildFreePlanCard() {
    // Find the free plan from the fetched plans
    final freePlan = _plans.isEmpty
        ? null
        : _plans.firstWhere(
            (p) => p.tier.toLowerCase() == 'free' || p.price == 0,
            orElse: () => _plans.first,
          );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                freePlan?.name ?? 'Free Plan',
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppPalette.navyPrimary,
                ),
              ),
              // Only show "Current" when user is actually on the free plan
              if (_subscriptionStatus != 'active' &&
                  _subscriptionStatus != 'trial')
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Current',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            freePlan?.description ?? 'Basic tools to get you started.',
            style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),
          if (freePlan != null && freePlan.features.isNotEmpty)
            ...freePlan.features.map(
              (f) => _buildFeatureItem(f.name, isPro: false),
            )
          else ...[
            _buildFeatureItem('Manage up to 5 players', isPro: false),
            _buildFeatureItem('Create 3 sessions/week', isPro: false),
            _buildFeatureItem('Basic Profile', isPro: false),
          ],
        ],
      ),
    );
  }

  Widget _buildProPlanCard(SubscriptionPlan plan) {
    // Assume plan.price is monthly price, calculate annual
    final monthlyPrice = plan.price;
    final annualPrice = _calculateAnnualPrice(monthlyPrice);
    final savings = _calculateSavings(monthlyPrice);
    final savingsPercent = 20; // 20% discount on annual

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF0F253E), // Dark Navy
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F253E).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plan.name,
                      style: GoogleFonts.inter(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      plan.description ?? 'Unlock your potential',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              if (_currentUserPlan != 'free' &&
                  (_subscriptionStatus == 'active' ||
                      _subscriptionStatus == 'trial') &&
                  // Checks if the user is currently on *this* Pro plan tier by checking plan name
                  (_currentUserPlan.contains(plan.name.toLowerCase())))
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF22C55E),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle,
                          color: Colors.white, size: 13),
                      const SizedBox(width: 4),
                      Text(
                        'ACTIVE',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                )
              else if (plan.isPopular)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF7D20),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'POPULAR',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),
          // Monthly Price
          GestureDetector(
            onTap: () {
              setState(() {
                _isAnnualSelected = false;
              });
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: !_isAnnualSelected
                    ? Colors.white.withValues(alpha: 0.2)
                    : Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: !_isAnnualSelected
                      ? Colors.white.withValues(alpha: 0.5)
                      : Colors.white.withValues(alpha: 0.2),
                  width: !_isAnnualSelected ? 2 : 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Monthly',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.7),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${_getCurrencySymbol(plan.currency)} $monthlyPrice',
                            style: GoogleFonts.inter(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              height: 1,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              '/mo',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: Colors.white.withValues(alpha: 0.7),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (!_isAnnualSelected ||
                      (_currentUserPlan.contains(plan.name.toLowerCase()) &&
                          _currentUserPlan.contains('monthly')))
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: (_currentUserPlan
                                    .contains(plan.name.toLowerCase()) &&
                                _currentUserPlan.contains('monthly'))
                            ? const Color(0xFF22C55E)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check,
                            color: (_currentUserPlan
                                        .contains(plan.name.toLowerCase()) &&
                                    _currentUserPlan.contains('monthly'))
                                ? Colors.white
                                : const Color(0xFF0F253E),
                            size: 14,
                          ),
                          if (_currentUserPlan
                                  .contains(plan.name.toLowerCase()) &&
                              _currentUserPlan.contains('monthly')) ...[
                            const SizedBox(width: 4),
                            Text(
                              'ACTIVE',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Annual Price
          GestureDetector(
            onTap: () {
              setState(() {
                _isAnnualSelected = true;
              });
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _isAnnualSelected
                    ? const Color(0xFF22C55E).withValues(alpha: 0.2)
                    : const Color(0xFF22C55E).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _isAnnualSelected
                      ? const Color(0xFF22C55E).withValues(alpha: 0.7)
                      : const Color(0xFF22C55E).withValues(alpha: 0.4),
                  width: _isAnnualSelected ? 2 : 2,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Annual',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.7),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF22C55E),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Save $savingsPercent%',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${_getCurrencySymbol(plan.currency)} $annualPrice',
                            style: GoogleFonts.inter(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              height: 1,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              '/yr',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: Colors.white.withValues(alpha: 0.7),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Save ${_getCurrencySymbol(plan.currency)} $savings/year',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF22C55E),
                        ),
                      ),
                    ],
                  ),
                  if (_isAnnualSelected ||
                      (_currentUserPlan.contains(plan.name.toLowerCase()) &&
                          _currentUserPlan.contains('yearly')))
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: (_currentUserPlan
                                    .contains(plan.name.toLowerCase()) &&
                                _currentUserPlan.contains('yearly'))
                            ? const Color(0xFF22C55E)
                            : const Color(
                                0xFF22C55E), // Annual selection also uses green when selected, but let's stick to the active badge logic
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check,
                            color: (_currentUserPlan
                                        .contains(plan.name.toLowerCase()) &&
                                    _currentUserPlan.contains('yearly'))
                                ? Colors.white
                                : Colors.white,
                            size: 14,
                          ),
                          if (_currentUserPlan
                                  .contains(plan.name.toLowerCase()) &&
                              _currentUserPlan.contains('yearly')) ...[
                            const SizedBox(width: 4),
                            Text(
                              'ACTIVE',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Divider(color: Colors.white12),
          const SizedBox(height: 20),
          // Features - Scrollable Section
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (plan.features.isNotEmpty)
                    ...plan.features.map(
                      (f) => _buildFeatureItem(f.name,
                          isPro: true, highlight: f.highlight),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        'Premium features included',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(String text,
      {required bool isPro, bool highlight = false}) {
    // Pro features: Green circle check, white text
    // Free features: Grey/Blue circle check, dark text
    // Highlighted features: Orange accent
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isPro
                  ? (highlight
                      ? AppPalette.orangeAccent
                      : const Color(0xFF22C55E))
                  : AppPalette.navyPrimary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check,
              size: 12,
              color: isPro ? Colors.white : AppPalette.navyPrimary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: highlight ? FontWeight.w700 : FontWeight.w500,
                color: isPro
                    ? (highlight ? AppPalette.orangeAccent : Colors.white)
                    : AppPalette.textPrimaryLight,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getCurrencySymbol(String currency) {
    return CurrencyHelper.getCurrencySymbol(currency);
  }
}
