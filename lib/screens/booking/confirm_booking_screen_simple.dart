import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/palette.dart';

import '../../services/booking_service.dart';
import '../../services/guardian_service.dart';

class ConfirmBookingScreenSimple extends StatefulWidget {
  final Map<String, dynamic> bookingDetails;

  const ConfirmBookingScreenSimple({super.key, this.bookingDetails = const {}});

  @override
  State<ConfirmBookingScreenSimple> createState() =>
      _ConfirmBookingScreenSimpleState();
}

class _ConfirmBookingScreenSimpleState
    extends State<ConfirmBookingScreenSimple> {
  final TextEditingController _promoController = TextEditingController();
  String? _appliedPromoCode;
  double _discountAmount = 0.0;
  String? _promoError;
  int _selectedPaymentMethod = 0; // 0: Card, 1: Apple Pay, 2: Test Booking
  bool _isProcessing = false;

  // Guardian specific
  bool _isGuardian = false;
  List<dynamic> _players = [];
  String? _selectedPlayerId;
  bool _isLoadingPlayers = false;

  final double _sessionFee = 60.00;
  final double _serviceFee = 2.50;
  final double _tax = 0.00;

  double get _totalAmount => _sessionFee + _serviceFee + _tax - _discountAmount;

  @override
  void initState() {
    super.initState();
    _checkUserRole();
  }

  Future<void> _checkUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    final role = prefs.getString('user_role');
    setState(() {
      _isGuardian = role == 'guardian';
    });

    if (_isGuardian) {
      _fetchPlayers();
    }
  }

  Future<void> _fetchPlayers() async {
    setState(() => _isLoadingPlayers = true);
    try {
      final players = await GuardianService().getMyPlayers();
      if (mounted) {
        setState(() {
          _players = players;
          if (_players.isNotEmpty) {
            _selectedPlayerId = _players[0]['_id'];
          }
        });
      }
    } catch (e) {
      debugPrint('Error fetching players: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingPlayers = false);
      }
    }
  }

  void _applyPromoCode() {
    final code = _promoController.text.trim().toUpperCase();
    if (code.isEmpty) return;

    setState(() {
      _promoError = null;
      if (code == 'SUMMER10') {
        _appliedPromoCode = 'SUMMER10';
        _discountAmount = 10.00;
      } else if (code == 'CRICKET50') {
        _appliedPromoCode = 'CRICKET50';
        _discountAmount = 30.00;
      } else {
        _promoError = "The code '$code' is invalid or has expired.";
        _appliedPromoCode = null;
        _discountAmount = 0.0;
      }
    });
  }

  void _removePromoCode() {
    setState(() {
      _promoController.clear();
      _appliedPromoCode = null;
      _discountAmount = 0.0;
      _promoError = null;
    });
  }

  @override
  void dispose() {
    _promoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final coachName = widget.bookingDetails['coachName'] ?? 'Michael Ray';
    final coachImage =
        widget.bookingDetails['coachImage'] ??
        'https://i.pravatar.cc/150?img=12';
    final dateStr = widget.bookingDetails['date'] ?? 'Tue, Oct 24';
    final timeStr = widget.bookingDetails['time'] ?? '10:00 AM';
    final location =
        widget.bookingDetails['location'] ?? 'Sunnydale Sports Complex';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Confirm Booking',
          style: GoogleFonts.outfit(
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
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Success banner if discount applied
                  if (_appliedPromoCode != null) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF22C55E),
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
                                  style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  "You're saving \$${_discountAmount.toStringAsFixed(2)} on this session.",
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
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Booking Summary Header
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
                      border: Border.all(
                        color: Theme.of(
                          context,
                        ).dividerColor.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 30,
                              backgroundImage: NetworkImage(coachImage),
                              backgroundColor: Colors.grey[200],
                              onBackgroundImageError:
                                  (exception, stackTrace) {},
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    coachName,
                                    style: GoogleFonts.outfit(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurface,
                                    ),
                                  ),
                                  Text(
                                    'Tennis Coaching • Private Session',
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
                        _buildInfoRow(
                          context,
                          Icons.calendar_today_rounded,
                          'DATE & TIME',
                          '$dateStr • $timeStr',
                        ),
                        const SizedBox(height: 16),
                        _buildInfoRow(
                          context,
                          Icons.location_on_rounded,
                          'LOCATION',
                          location,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Player Selection (For Guardians)
                  if (_isGuardian) ...[
                    Text(
                      'BOOKING FOR',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.0,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_isLoadingPlayers)
                      const Center(child: CircularProgressIndicator())
                    else if (_players.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppPalette.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppPalette.error.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.warning_amber_rounded,
                              color: AppPalette.error,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'You need to add a player to your account first.',
                                style: GoogleFonts.inter(
                                  color: AppPalette.error,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () =>
                                  context.push('/guardian/add-player'),
                              child: const Text('Add Player'),
                            ),
                          ],
                        ),
                      )
                    else
                      Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Theme.of(
                              context,
                            ).dividerColor.withValues(alpha: 0.1),
                          ),
                        ),
                        child: RadioGroup<String?>(
                          groupValue: _selectedPlayerId,
                          onChanged: (value) {
                            setState(() {
                              _selectedPlayerId = value;
                            });
                          },
                          child: Column(
                            children: _players.map((player) {
                              final isSelected =
                                  _selectedPlayerId == player['_id'];
                              return RadioListTile<String>(
                                value: player['_id'],
                                title: Text(
                                  player['fullName'],
                                  style: GoogleFonts.outfit(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                secondary: CircleAvatar(
                                  backgroundImage: NetworkImage(
                                    player['profilePhoto'] ??
                                        'https://i.pravatar.cc/150?u=${player['_id']}',
                                  ),
                                ),
                                activeColor: AppPalette.navyPrimary,
                                selected: isSelected,
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    const SizedBox(height: 32),
                  ],

                  // Price Breakdown
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
                      border: Border.all(
                        color: Theme.of(
                          context,
                        ).dividerColor.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Column(
                      children: [
                        _buildPriceRow(
                          context,
                          'Session Fee (1hr)',
                          _sessionFee,
                        ),
                        const SizedBox(height: 12),
                        _buildPriceRow(context, 'Service Fee', _serviceFee),
                        const SizedBox(height: 12),
                        _buildPriceRow(context, 'Tax', _tax),
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
                              style: GoogleFonts.outfit(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            Text(
                              '\$${_totalAmount.toStringAsFixed(2)}',
                              style: GoogleFonts.outfit(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Promo Code Section
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
                                style: GoogleFonts.outfit(
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
                        border: Border.all(
                          color: Theme.of(
                            context,
                          ).dividerColor.withValues(alpha: 0.1),
                        ),
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 12),
                          Icon(
                            Icons.local_offer_outlined,
                            color: Theme.of(context).hintColor,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _promoController,
                              style: GoogleFonts.inter(
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                              decoration: InputDecoration(
                                hintText: 'ENTER PROMO CODE',
                                border: InputBorder.none,
                                hintStyle: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: Theme.of(context).hintColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                          ElevatedButton(
                            onPressed: _applyPromoCode,
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
                            child: Text(
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
                      ),
                    ),

                  const SizedBox(height: 32),

                  // Payment Method
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

                  _buildPaymentOption(
                    context,
                    index: 0,
                    icon: Icons.credit_card,
                    title: 'Visa ending in 4242',
                    subtitle: 'Expires 12/25',
                  ),
                  const SizedBox(height: 12),
                  _buildPaymentOption(
                    context,
                    index: 1,
                    icon: Icons.apple,
                    title: 'Apple Pay',
                  ),
                  const SizedBox(height: 12),
                  _buildPaymentOption(
                    context,
                    index: 2,
                    icon: Icons.bug_report,
                    title: 'Test Booking',
                    subtitle: 'For testing purposes only',
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),

          // Bottom Pay Button
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
              border: Border(
                top: BorderSide(
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                ),
              ),
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
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isProcessing
                        ? null
                        : () async {
                            if (_isGuardian &&
                                _players.isNotEmpty &&
                                _selectedPlayerId == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Please select a player'),
                                  backgroundColor: AppPalette.error,
                                ),
                              );
                              return;
                            }

                            if (_isGuardian && _players.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Please add a player to your account first',
                                  ),
                                  backgroundColor: AppPalette.error,
                                ),
                              );
                              return;
                            }

                            setState(() {
                              _isProcessing = true;
                            });

                            try {
                              // Map payment method index to string
                              String paymentMethodStr = 'card';
                              if (_selectedPaymentMethod == 1) {
                                paymentMethodStr = 'apple_pay';
                              } else if (_selectedPaymentMethod == 2) {
                                paymentMethodStr = 'test';
                              }

                              final sessionId =
                                  widget.bookingDetails['sessionId'];
                              final occurrenceDate =
                                  widget.bookingDetails['occurrenceDate'];
                              final promoCode = _appliedPromoCode;

                              if (sessionId == null || occurrenceDate == null) {
                                throw Exception('Missing booking details');
                              }

                              // Call API
                              await BookingService.createBooking(
                                sessionId: sessionId,
                                occurrenceDate: occurrenceDate,
                                paymentMethod: paymentMethodStr,
                                promoCode: promoCode,
                                playerId: _selectedPlayerId,
                              );

                              if (context.mounted) {
                                context.push(
                                  '/booking-success',
                                  extra: widget.bookingDetails,
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Booking failed: $e'),
                                    backgroundColor: AppPalette.error,
                                  ),
                                );
                              }
                            } finally {
                              if (mounted) {
                                setState(() {
                                  _isProcessing = false;
                                });
                              }
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppPalette.orangeAccent,
                      foregroundColor: Colors.white,
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isProcessing
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Pay Total',
                                style: GoogleFonts.outfit(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '\$${_totalAmount.toStringAsFixed(2)}',
                                style: GoogleFonts.outfit(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
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
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppPalette.orangeAccent.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppPalette.orangeAccent, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPriceRow(BuildContext context, String label, double amount) {
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
          '\$${amount.toStringAsFixed(2)}',
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentOption(
    BuildContext context, {
    required int index,
    required IconData icon,
    required String title,
    String? subtitle,
  }) {
    final isSelected = _selectedPaymentMethod == index;

    return GestureDetector(
      onTap: () => setState(() => _selectedPaymentMethod = index),
      child: Container(
        width: double.infinity,
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
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: Theme.of(context).colorScheme.onSurface),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 15,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                        fontSize: 13,
                      ),
                    ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: AppPalette.orangeAccent),
          ],
        ),
      ),
    );
  }
}
