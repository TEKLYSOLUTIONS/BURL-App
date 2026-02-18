import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../config/palette.dart';
import '../../models/subscription_plan.dart';
import '../../services/subscription_service.dart';
import '../../utils/currency_helper.dart';
import 'subscription_result_screen.dart';

class SubscriptionPaymentScreen extends StatefulWidget {
  final SubscriptionPlan plan;
  final bool isAnnual;
  final String currency;
  final String? userId;

  const SubscriptionPaymentScreen({
    super.key,
    required this.plan,
    required this.isAnnual,
    required this.currency,
    this.userId,
  });

  @override
  State<SubscriptionPaymentScreen> createState() =>
      _SubscriptionPaymentScreenState();
}

class _SubscriptionPaymentScreenState
    extends State<SubscriptionPaymentScreen> {
  final TextEditingController _promoController = TextEditingController();
  final _subscriptionService = SubscriptionService();

  PromoCodeValidation? _appliedPromo;
  bool _isValidatingPromo = false;
  String? _promoError;
  bool _isProcessing = false;

  // ─── Test card options ────────────────────────────────────────────────────
  // Using Stripe's official test card numbers for simulation
  static const _testCards = [
    {
      'label': 'Visa — Payment succeeds',
      'number': '4242 4242 4242 4242',
      'expiry': '12/26',
      'cvc': '123',
      'icon': Icons.credit_card,
      'color': 0xFF1A73E8,
      'succeeds': true,
    },
    {
      'label': 'Visa — Card declined',
      'number': '4000 0000 0000 0002',
      'expiry': '12/26',
      'cvc': '123',
      'icon': Icons.credit_card_off_outlined,
      'color': 0xFFE53935,
      'succeeds': false,
    },
    {
      'label': 'Mastercard — Insufficient funds',
      'number': '5105 1051 0510 5100',
      'expiry': '12/26',
      'cvc': '123',
      'icon': Icons.credit_card_off_outlined,
      'color': 0xFFFF6D00,
      'succeeds': false,
    },
  ];

  int _selectedCardIndex = 0;

  // ─── Pricing helpers ───────────────────────────────────────────────────────

  int get _monthlyPrice => widget.plan.price;

  int get _annualPrice => (_monthlyPrice * 12 * 0.8).round();

  int get _annualSavings => (_monthlyPrice * 12) - _annualPrice;

  double get _basePrice =>
      widget.isAnnual ? _annualPrice.toDouble() : _monthlyPrice.toDouble();

  double get _promoDiscount {
    if (_appliedPromo == null) return 0.0;
    if (_appliedPromo!.discountType == 'percentage') {
      return (_basePrice * _appliedPromo!.discountValue / 100)
          .clamp(0, double.infinity);
    }
    return _appliedPromo!.discountValue.clamp(0, double.infinity);
  }

  double get _totalAmount => (_basePrice - _promoDiscount).clamp(0, double.infinity);

  String get _sym => CurrencyHelper.getCurrencySymbol(widget.currency);

  String _fmt(double v) => '$_sym ${v.toStringAsFixed(2)}';

  // ─── Promo code ─────────────────────────────────────────────────────────────

  Future<void> _applyPromoCode() async {
    final code = _promoController.text.trim();
    if (code.isEmpty) return;

    setState(() {
      _isValidatingPromo = true;
      _promoError = null;
    });

    try {
      final validation = await _subscriptionService.validatePromoCode(
        code: code,
        planId: widget.plan.id,
        userId: widget.userId,
      );

      if (mounted) {
        setState(() {
          _appliedPromo = validation;
          _promoError = null;
        });
        _promoController.clear();
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _promoError = error.toString().replaceAll('Exception: ', '');
          _appliedPromo = null;
        });
      }
    } finally {
      if (mounted) setState(() => _isValidatingPromo = false);
    }
  }

  void _removePromo() {
    setState(() {
      _appliedPromo = null;
      _promoError = null;
      _promoController.clear();
    });
  }

  // ─── Subscribe ───────────────────────────────────────────────────────────────

  Future<void> _handleSubscribe() async {
    setState(() => _isProcessing = true);

    // Simulate network latency for test payment processing
    await Future.delayed(const Duration(milliseconds: 1800));

    final selectedCard = _testCards[_selectedCardIndex];
    final succeeds = selectedCard['succeeds'] as bool;

    String? errorMsg;
    if (succeeds) {
      try {
        await _subscriptionService.activateSubscription(
          planId: widget.plan.planId,
          isAnnual: widget.isAnnual,
        );
      } catch (e) {
        errorMsg = e.toString().replaceAll('Exception: ', '');
      }
    }

    if (!mounted) return;
    setState(() => _isProcessing = false);

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => SubscriptionResultScreen(
          success: succeeds && errorMsg == null,
          planName: widget.plan.name,
          billingCycle: widget.isAnnual
              ? 'Annual (billed yearly)'
              : 'Monthly',
          totalPaid: _fmt(_totalAmount),
          currency: _sym,
          promoCode: _appliedPromo?.code,
          promoDiscount: _promoDiscount,
          errorMessage: !succeeds
              ? 'Your card was declined. Please use a different card.'
              : errorMsg,
          trialDays: widget.plan.trialPeriodDays,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _promoController.dispose();
    super.dispose();
  }

  // ─── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        title: Text(
          'Confirm Subscription',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            color: AppPalette.navyPrimary,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          color: AppPalette.navyPrimary,
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Applied promo banner
                  if (_appliedPromo != null) ...[
                    _buildAppliedPromoBanner(),
                    const SizedBox(height: 20),
                  ],

                  // PLAN SUMMARY
                  _buildSectionLabel('PLAN SUMMARY'),
                  const SizedBox(height: 10),
                  _buildPlanSummaryCard(),

                  const SizedBox(height: 24),

                  // PRICE BREAKDOWN
                  _buildSectionLabel('PRICE BREAKDOWN'),
                  const SizedBox(height: 10),
                  _buildPriceBreakdownCard(),

                  const SizedBox(height: 20),

                  // Promo error
                  if (_promoError != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline,
                              color: Colors.red, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _promoError!,
                              style: GoogleFonts.inter(
                                  color: Colors.red, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],

                  // PROMO CODE
                  if (_appliedPromo != null)
                    _buildAppliedPromoRow()
                  else
                    _buildPromoCodeInput(),

                  const SizedBox(height: 24),

                  // PAYMENT METHOD
                  _buildSectionLabel('PAYMENT METHOD'),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: Colors.amber.withValues(alpha: 0.35)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline,
                            size: 15, color: Colors.amber[700]),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Test mode — select a card to simulate success or failure',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: Colors.amber[800],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildTestCardSelector(),

                  const SizedBox(height: 12),

                  Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.lock_outline,
                            size: 14, color: Colors.grey[500]),
                        const SizedBox(width: 6),
                        Text(
                          'Payments are secure and encrypted',
                          style: GoogleFonts.inter(
                              fontSize: 12, color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // ─── Bottom CTA ─────────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _isProcessing ? null : _handleSubscribe,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppPalette.orangeAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: _isProcessing
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2.5),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            widget.plan.trialPeriodDays > 0
                                ? 'Start Free Trial'
                                : 'Subscribe Now',
                            style: GoogleFonts.inter(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            _fmt(_totalAmount),
                            style: GoogleFonts.inter(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Section helpers ────────────────────────────────────────────────────────

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
        color: Colors.grey[600],
      ),
    );
  }

  // ─── Plan Summary Card ───────────────────────────────────────────────────────

  Widget _buildPlanSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppPalette.navyPrimary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.workspace_premium,
                    color: Colors.white, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.plan.name,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                        color: AppPalette.navyPrimary,
                      ),
                    ),
                    Text(
                      widget.plan.description ??
                          'Unlock your coaching potential',
                      style: GoogleFonts.inter(
                          fontSize: 12, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(Icons.star,
                            size: 13, color: AppPalette.orangeAccent),
                        const SizedBox(width: 4),
                        Text(
                          'PRO PLAN',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppPalette.orangeAccent,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Divider(color: Colors.grey.shade200, height: 1),
          ),
          _buildInfoRow(
            Icons.calendar_month_rounded,
            const Color(0xFFEEF2FF),
            AppPalette.navyPrimary,
            'BILLING CYCLE',
            widget.isAnnual ? 'Annual (billed yearly)' : 'Monthly',
          ),
          if (widget.plan.trialPeriodDays > 0) ...[
            const SizedBox(height: 14),
            _buildInfoRow(
              Icons.card_giftcard_rounded,
              const Color(0xFFFFF3E0),
              AppPalette.orangeAccent,
              'FREE TRIAL',
              '${widget.plan.trialPeriodDays} days — no charge today',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    Color bgColor,
    Color iconColor,
    String label,
    String value,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
              color: bgColor, borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: iconColor, size: 18),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey[500],
                  letterSpacing: 0.8,
                ),
              ),
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppPalette.navyPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Price Breakdown ─────────────────────────────────────────────────────────

  Widget _buildPriceBreakdownCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          if (widget.isAnnual) ...[
            _buildPriceRow(
                '${widget.plan.name} (Monthly)', _fmt(_monthlyPrice.toDouble())),
            const SizedBox(height: 10),
            _buildPriceRow('× 12 months',
                _fmt((_monthlyPrice * 12).toDouble())),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.discount_outlined,
                        size: 15, color: Color(0xFF22C55E)),
                    const SizedBox(width: 6),
                    Text(
                      'Annual Discount (20%)',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: const Color(0xFF22C55E),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                Text(
                  '-${_fmt(_annualSavings.toDouble())}',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF22C55E),
                  ),
                ),
              ],
            ),
          ] else
            _buildPriceRow(
                '${widget.plan.name} (Monthly)', _fmt(_monthlyPrice.toDouble())),

          if (_appliedPromo != null) ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.local_offer,
                        size: 15, color: Color(0xFF22C55E)),
                    const SizedBox(width: 6),
                    Text(
                      'Promo (${_appliedPromo!.code})',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: const Color(0xFF22C55E),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                Text(
                  '-${_fmt(_promoDiscount)}',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF22C55E),
                  ),
                ),
              ],
            ),
          ],

          Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Divider(color: Colors.grey.shade200, height: 1),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total',
                style: GoogleFonts.inter(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: AppPalette.navyPrimary,
                ),
              ),
              Text(
                _fmt(_totalAmount),
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppPalette.navyPrimary,
                ),
              ),
            ],
          ),

          if (widget.plan.trialPeriodDays > 0) ...[
            const SizedBox(height: 10),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF22C55E).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.info_outline,
                      size: 14, color: Color(0xFF22C55E)),
                  const SizedBox(width: 6),
                  Text(
                    'No charge for ${widget.plan.trialPeriodDays} days — cancel anytime',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: const Color(0xFF22C55E),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, String amount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[600])),
        Text(
          amount,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppPalette.navyPrimary,
          ),
        ),
      ],
    );
  }

  // ─── Promo Code ──────────────────────────────────────────────────────────────

  Widget _buildAppliedPromoBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF22C55E),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.white, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Promo Code Applied!',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                Text(
                  _appliedPromo!.discountType == 'percentage'
                      ? '${_appliedPromo!.discountValue.toStringAsFixed(0)}% off — you save ${_fmt(_promoDiscount)}'
                      : 'You save ${_fmt(_promoDiscount)}',
                  style: GoogleFonts.inter(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPromoCodeInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.local_offer_outlined, color: Colors.grey[400], size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _promoController,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                hintText: 'ENTER PROMO CODE',
                hintStyle: GoogleFonts.inter(
                  fontSize: 13,
                  color: Colors.grey[400],
                  letterSpacing: 0.5,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 10),
              ),
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: AppPalette.navyPrimary,
              ),
            ),
          ),
          TextButton(
            onPressed: _isValidatingPromo ? null : _applyPromoCode,
            child: _isValidatingPromo
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child:
                        CircularProgressIndicator(strokeWidth: 2))
                : Text(
                    'Apply',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      color: AppPalette.orangeAccent,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppliedPromoRow() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: const Color(0xFF22C55E).withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle,
              color: Color(0xFF22C55E), size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _appliedPromo!.code,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                color: const Color(0xFF22C55E),
                fontSize: 15,
              ),
            ),
          ),
          TextButton(
            onPressed: _removePromo,
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
              backgroundColor: Colors.red.withValues(alpha: 0.08),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(
              'Remove',
              style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Test Card Selector ─────────────────────────────────────────────────────

  Widget _buildTestCardSelector() {
    return Column(
      children: List.generate(_testCards.length, (index) {
        final card = _testCards[index];
        final isSelected = _selectedCardIndex == index;
        final succeeds = card['succeeds'] as bool;
        final cardColor = Color(card['color'] as int);

        return GestureDetector(
          onTap: () => setState(() => _selectedCardIndex = index),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected ? cardColor : Colors.grey.shade200,
                width: isSelected ? 2 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: cardColor.withValues(alpha: 0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      )
                    ]
                  : [],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: cardColor.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    card['icon'] as IconData,
                    color: cardColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        card['label'] as String,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: AppPalette.navyPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '•••• •••• •••• ${(card['number'] as String).split(' ').last}  ${card['expiry']}  CVC ${card['cvc']}',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: Colors.grey[500],
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: succeeds
                        ? const Color(0xFF22C55E).withValues(alpha: 0.1)
                        : Colors.red.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    succeeds ? 'SUCCESS' : 'DECLINE',
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: succeeds
                          ? const Color(0xFF22C55E)
                          : Colors.red.shade400,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Icon(
                  isSelected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color:
                      isSelected ? cardColor : Colors.grey[400],
                  size: 22,
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

}
