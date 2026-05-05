import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../config/palette.dart';
import '../../services/booking_service.dart';
import '../../services/commission_service.dart';
import '../../services/stripe_payment_service.dart';

class ConfirmBookingScreen extends StatefulWidget {
  final Map<String, dynamic> bookingDetails;

  const ConfirmBookingScreen({super.key, this.bookingDetails = const {}});

  @override
  State<ConfirmBookingScreen> createState() => _ConfirmBookingScreenState();
}

class _ConfirmBookingScreenState extends State<ConfirmBookingScreen> {
  final TextEditingController _promoController = TextEditingController();
  final _stripeService = StripePaymentService();
  String? _appliedPromoCode;
  double _discountAmount = 0.0;
  String? _promoError;
  bool _isValidatingPromo = false;
  bool _isProcessingPayment = false;
  bool _addingCard = false;

  // Pricing values — loaded dynamically from the backend
  bool _isLoadingCommission = true;
  double _sessionFee = 60.0;
  CommissionResult? _commissionResult;

  double get _serviceFee => _commissionResult?.commissionAmount ?? 0.0;
  String get _serviceFeeLabel => _commissionResult?.label ?? 'Platform Fee';
  final double _tax = 0.00;

  // Real Stripe saved cards
  List<Map<String, dynamic>> _savedCards = [];
  String? _selectedPaymentMethodId;

  double get _totalAmount => _sessionFee + _serviceFee + _tax - _discountAmount;

  @override
  void initState() {
    super.initState();
    _loadCommission();
    _loadCards();
  }

  Future<void> _loadCards() async {
    try {
      final cards = await _stripeService.listCards();
      if (mounted) {
        setState(() {
          _savedCards = cards;
          if (cards.isNotEmpty) _selectedPaymentMethodId = cards[0]['id'] as String;
        });
      }
    } catch (e) {
      debugPrint('Error loading cards: $e');
    }
  }

  Future<void> _addCard() async {
    setState(() => _addingCard = true);
    try {
      final success = await _stripeService.addCard(context);
      if (success && mounted) {
        await _loadCards();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Card added successfully'),
            backgroundColor: AppPalette.successGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to add card. Please try again.'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _addingCard = false);
    }
  }

  Future<void> _loadCommission() async {
    final session = widget.bookingDetails['session'];
    final rawFee =
        (session?['pricing']?['amount'] as num?)?.toDouble() ??
        (widget.bookingDetails['sessionFee'] as num?)?.toDouble() ??
        60.0;

    final sportName = session?['sport']?.toString() ??
        session?['category']?.toString() ??
        session?['title']?.toString();

    try {
      final result = await CommissionService.calculate(
        rawFee,
        sportName: sportName,
      );
      if (mounted) {
        setState(() {
          _sessionFee = rawFee;
          _commissionResult = result;
          _isLoadingCommission = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _sessionFee = rawFee;
          _commissionResult = CommissionResult.fromFallback(rawFee);
          _isLoadingCommission = false;
        });
      }
    }
  }

  Future<void> _applyPromoCode() async {
    final code = _promoController.text.trim().toUpperCase();
    if (code.isEmpty) return;

    setState(() {
      _isValidatingPromo = true;
      _promoError = null;
    });

    try {
      final result = await BookingService.validatePromoCode(code);

      setState(() {
        _isValidatingPromo = false;
        if (result['valid'] == true) {
          _appliedPromoCode = result['code'] as String? ?? code;
          final discountType = result['discountType'] as String? ?? 'fixed';
          final discountValue =
              (result['discountValue'] as num?)?.toDouble() ?? 0.0;
          if (discountType == 'percentage') {
            _discountAmount = _sessionFee * (discountValue / 100);
          } else {
            _discountAmount = discountValue;
          }
          _discountAmount = _discountAmount.clamp(0.0, _sessionFee);
          _promoError = null;
        } else {
          _appliedPromoCode = null;
          _discountAmount = 0.0;
          _promoError = result['message'] as String? ??
              "The code '$code' is invalid or has expired.";
        }
      });
    } catch (e) {
      setState(() {
        _isValidatingPromo = false;
        _promoError = 'Error validating promo code';
      });
    }
  }

  void _removePromoCode() {
    setState(() {
      _promoController.clear();
      _appliedPromoCode = null;
      _discountAmount = 0.0;
      _promoError = null;
    });
  }

  Future<void> _processPayment() async {
    if (_selectedPaymentMethodId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add a payment card first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    setState(() => _isProcessingPayment = true);

    try {
      final sessionId = widget.bookingDetails['sessionId'];
      final occurrenceDate = widget.bookingDetails['occurrenceDate'];
      final List<String>? selectedDates =
          (widget.bookingDetails['selectedDates'] as List?)?.cast<String>();

      if (sessionId == null ||
          (occurrenceDate == null && selectedDates == null)) {
        throw Exception('Missing booking details');
      }

      final booking = await BookingService.createBooking(
        sessionId: sessionId,
        occurrenceDate: occurrenceDate,
        occurrenceDates: selectedDates,
        paymentMethod: 'card',
        paymentMethodId: _selectedPaymentMethodId,
        promoCode: _appliedPromoCode,
      );

      if (mounted) {
        setState(() => _isProcessingPayment = false);
        context.push(
          '/booking-success',
          extra: {'bookingId': booking['_id'], ...widget.bookingDetails},
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessingPayment = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Booking failed: ${e.toString()}'),
            backgroundColor: AppPalette.error,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _promoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Show loading while commission is being fetched
    if (_isLoadingCommission) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text(
            'Confirm Booking',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new,
              color: Theme.of(context).iconTheme.color,
            ),
            onPressed: () => context.pop(),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // Determine dynamic values with fallbacks
    final session = widget.bookingDetails['session'];
    Map<String, dynamic>? coachData;
    if (session != null) {
      final createdByValue = session['createdBy'];
      final coachValue = session['coach'];
      if (createdByValue is Map) {
        coachData = Map<String, dynamic>.from(createdByValue);
      } else if (coachValue is Map) {
        final m = Map<String, dynamic>.from(coachValue);
        if (m['coachProfile'] is Map) {
          coachData = Map<String, dynamic>.from(m['coachProfile']);
        } else {
          coachData = m;
        }
      }
    }

    final coachName = coachData?['fullName']?.toString() ??
        widget.bookingDetails['coachName']?.toString() ??
        session?['coachName']?.toString() ??
        'Michael Ray';

    final sessionImage =
        session?['imageUrl']?.toString() ?? session?['coverImage']?.toString();
    final profilePhoto = coachData?['profilePhoto']?.toString() ??
        coachData?['avatarUrl']?.toString();
    final coachImage = widget.bookingDetails['coachImage']?.toString() ??
        profilePhoto ??
        sessionImage;

    final dateStr = widget.bookingDetails['date'] ?? 'Tue, Oct 24';
    final timeStr = widget.bookingDetails['time'] ?? '10:00 AM';
    final location =
        widget.bookingDetails['location'] ?? 'Sunnydale Sports Complex';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Confirm Booking',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: Theme.of(context).iconTheme.color,
          ),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Success Message if Discount Applied
                    if (_appliedPromoCode != null) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF22C55E), // Green
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle, color: Colors.white),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Discount Applied!',
                                    style: GoogleFonts.inter(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    "You're saving \$${_discountAmount.toStringAsFixed(2)} on this session.",
                                    style: GoogleFonts.inter(
                                      color: Colors.white.withValues(
                                        alpha: 0.9,
                                      ),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn().slideY(begin: -0.2),
                      const SizedBox(height: 24),
                    ],

                    // BOOKING SUMMARY HEADER
                    Text(
                      'BOOKING SUMMARY',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.0,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Booking Summary Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Coach Info
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 30,
                                backgroundImage: NetworkImage(coachImage ??
                                    'https://i.pravatar.cc/150?img=12'),
                                onBackgroundImageError:
                                    (exception, stackTrace) {},
                                backgroundColor: Theme.of(
                                  context,
                                ).colorScheme.surfaceContainerHighest,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      coachName,
                                      style: GoogleFonts.inter(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurface,
                                      ),
                                    ),
                                    Text(
                                      'Cricket Coaching • Session',
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        color: Theme.of(
                                          context,
                                        ).textTheme.bodyMedium?.color,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.verified,
                                          size: 14,
                                          color: AppPalette.orangeAccent,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'TOP RATED COACH',
                                          style: GoogleFonts.inter(
                                            fontSize: 11,
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
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            child: Divider(
                              color: Theme.of(context).dividerColor,
                              height: 1,
                            ),
                          ),
                          // Date & Time
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppPalette.orangeAccent.withValues(
                                    alpha: 0.1,
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.calendar_today_rounded,
                                  color: AppPalette.orangeAccent,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'DATE & TIME',
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: Theme.of(
                                          context,
                                        ).textTheme.bodyMedium?.color,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '$dateStr • $timeStr',
                                      style: GoogleFonts.inter(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurface,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Location
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppPalette.orangeAccent.withValues(
                                    alpha: 0.1,
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.location_on_rounded,
                                  color: AppPalette.orangeAccent,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'LOCATION',
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: Theme.of(
                                          context,
                                        ).textTheme.bodyMedium?.color,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      location,
                                      style: GoogleFonts.inter(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurface,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ).animate().fadeIn(),

                    const SizedBox(height: 32),

                    // PRICE BREAKDOWN HEADER
                    Text(
                      'PRICE BREAKDOWN',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.0,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 12),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          _buildPriceRow('Session Fee', _sessionFee),
                          const SizedBox(height: 12),
                          _buildPriceRow(_serviceFeeLabel, _serviceFee),
                          const SizedBox(height: 12),
                          _buildPriceRow('Tax', _tax),
                          if (_appliedPromoCode != null) ...[
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.local_offer,
                                      size: 16,
                                      color: Colors.green,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Discount ($_appliedPromoCode)',
                                      style: GoogleFonts.inter(
                                        fontSize: 15,
                                        color: Colors.green,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  '-\$${_discountAmount.toStringAsFixed(2)}',
                                  style: GoogleFonts.inter(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                          ],
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Divider(
                              color: Theme.of(context).dividerColor,
                              height: 1,
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Total',
                                style: GoogleFonts.inter(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface,
                                ),
                              ),
                              Text(
                                '\$ ${_totalAmount.toStringAsFixed(2)}',
                                style: GoogleFonts.inter(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 100.ms),

                    const SizedBox(height: 24),

                    // PROMO CODE SECTION
                    if (_appliedPromoCode != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.green.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  _appliedPromoCode!,
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                            TextButton(
                              onPressed: _removePromoCode,
                              style: TextButton.styleFrom(
                                foregroundColor: AppPalette.error,
                                backgroundColor: AppPalette.error.withValues(
                                  alpha: 0.1,
                                ),
                              ),
                              child: Text(
                                'Remove',
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      // Promo Input
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            const SizedBox(width: 12),
                            const Icon(
                              Icons.local_offer_outlined,
                              color: AppPalette.textDisabled,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: _promoController,
                                style: GoogleFonts.inter(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'ENTER PROMO CODE',
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  hintStyle: GoogleFonts.inter(
                                    fontSize: 14,
                                    color: AppPalette.textDisabled,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                            ElevatedButton(
                              onPressed:
                                  _isValidatingPromo ? null : _applyPromoCode,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppPalette.orangeAccent
                                    .withValues(alpha: 0.1),
                                foregroundColor: AppPalette.orangeAccent,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
                              ),
                              child: _isValidatingPromo
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                          AppPalette.orangeAccent,
                                        ),
                                      ),
                                    )
                                  : Text(
                                      'Apply',
                                      style: GoogleFonts.inter(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ],
                        ),
                      ),

                    if (_promoError != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppPalette.error.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppPalette.error.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.error,
                                color: AppPalette.error,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _promoError!,
                                  style: GoogleFonts.inter(
                                    color: AppPalette.error,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ).animate().fadeIn(),
                      ),

                    const SizedBox(height: 32),

                    // PAYMENT METHOD HEADER
                    Text(
                      'PAYMENT METHOD',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.0,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Real Stripe card selector
                    _buildCardSelector(),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),

            // BOTTOM PAY BUTTON AREA
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.lock,
                        size: 14,
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Payments are secure and encrypted',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color:
                              Theme.of(context).textTheme.bodyMedium?.color,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isProcessingPayment ? null : _processPayment,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppPalette.navyPrimary,
                        foregroundColor: Colors.white,
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _isProcessingPayment
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Pay Total',
                                  style: GoogleFonts.inter(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  '\$ ${_totalAmount.toStringAsFixed(2)}',
                                  style: GoogleFonts.inter(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceRow(String label, double amount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 15,
            color: Theme.of(context).textTheme.bodyMedium?.color,
          ),
        ),
        Text(
          '\$ ${amount.toStringAsFixed(2)}',
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildCardSelector() {
    if (_savedCards.isEmpty) {
      // Empty state with inline Add Card button
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.credit_card_off_rounded,
                      color: Colors.orange, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'No payment cards saved',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        'Add a card to complete booking',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _addingCard ? null : _addCard,
                icon: _addingCard
                    ? const SizedBox(
                        width: 16, height: 16,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.add, size: 18),
                label: Text(
                  _addingCard ? 'Opening...' : '+ Add Card',
                  style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppPalette.navyPrimary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Has cards — show selectable list + Add Card at bottom
    return Column(
      children: [
        ..._savedCards.map((pm) {
          final pmId = pm['id'] as String;
          final cardData = pm['card'] as Map<String, dynamic>;
          final brand = (cardData['brand'] as String? ?? 'card');
          final last4 = (cardData['last4'] as String? ?? '••••');
          final expMonth =
              cardData['exp_month']?.toString().padLeft(2, '0') ?? '??';
          final expYear =
              cardData['exp_year']?.toString().substring(2) ?? '??';
          final isSelected = _selectedPaymentMethodId == pmId;

          return GestureDetector(
            onTap: () =>
                setState(() => _selectedPaymentMethodId = pmId),
            child: AnimatedContainer(
              duration: 200.ms,
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppPalette.orangeAccent.withValues(alpha: 0.05)
                    : Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected
                      ? AppPalette.orangeAccent
                      : Theme.of(context).dividerColor,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppPalette.navyPrimary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.credit_card,
                        color: AppPalette.navyPrimary, size: 20),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${brand[0].toUpperCase()}${brand.substring(1)} ending in $last4',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          'Expires $expMonth/$expYear',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    isSelected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    color: isSelected
                        ? AppPalette.orangeAccent
                        : Theme.of(context).disabledColor,
                    size: 22,
                  ),
                ],
              ),
            ),
          );
        }),

        // Add another card
        GestureDetector(
          onTap: _addingCard ? null : _addCard,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              border: Border.all(
                color: Theme.of(context).dividerColor,
                style: BorderStyle.solid,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: _addingCard
                  ? const SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_circle_outline,
                            color: Theme.of(context).colorScheme.primary,
                            size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Add New Card',
                          style: GoogleFonts.inter(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ],
    );
  }
}
