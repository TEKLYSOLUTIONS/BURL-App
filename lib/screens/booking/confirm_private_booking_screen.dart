import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/palette.dart';
import '../../services/booking_service.dart';
import '../../services/guardian_service.dart';

class ConfirmPrivateBookingScreen extends StatefulWidget {
  final String coachId;
  final String coachName;
  final DateTime startTime;
  final int durationMinutes;
  final double price;

  const ConfirmPrivateBookingScreen({
    super.key,
    required this.coachId,
    required this.coachName,
    required this.startTime,
    this.durationMinutes = 60,
    this.price = 60.0,
  });

  @override
  State<ConfirmPrivateBookingScreen> createState() =>
      _ConfirmPrivateBookingScreenState();
}

class _ConfirmPrivateBookingScreenState
    extends State<ConfirmPrivateBookingScreen> {
  final TextEditingController _promoController = TextEditingController();
  bool _isProcessing = false;

  // Promo code state
  String? _appliedPromoCode;
  double _discountAmount = 0.0;
  String? _promoError;
  bool _isValidatingPromo = false;

  // Guardian state
  bool _isGuardian = false;
  List<dynamic> _players = [];
  String? _selectedPlayerId;
  bool _isLoadingPlayers = false;

  // Pricing
  double get _sessionFee => widget.price;
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
    if (!mounted) return;
    final role = prefs.getString('user_role');
    setState(() => _isGuardian = role == 'guardian');
    if (_isGuardian) _fetchPlayers();
  }

  Future<void> _fetchPlayers() async {
    setState(() => _isLoadingPlayers = true);
    try {
      final players = await GuardianService().getMyPlayers();
      if (mounted) {
        setState(() {
          _players = players;
          if (_players.isNotEmpty) _selectedPlayerId = _players[0]['_id'];
        });
      }
    } catch (e) {
      debugPrint('Error fetching players: $e');
    } finally {
      if (mounted) setState(() => _isLoadingPlayers = false);
    }
  }

  Future<void> _applyPromoCode() async {
    final code = _promoController.text.trim();
    if (code.isEmpty) return;

    setState(() {
      _isValidatingPromo = true;
      _promoError = null;
    });

    try {
      final result = await BookingService.validatePromoCode(code);
      if (!mounted) return;

      if (result['valid'] == true) {
        setState(() {
          _appliedPromoCode = result['code'] ?? code.toUpperCase();
          _discountAmount = (result['discount'] as num?)?.toDouble() ?? 0.0;
          _promoError = null;
        });
      } else {
        setState(() {
          _promoError = result['message'] ?? 'Invalid promo code';
          _appliedPromoCode = null;
          _discountAmount = 0.0;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _promoError = 'Failed to validate promo code';
        });
      }
    } finally {
      if (mounted) setState(() => _isValidatingPromo = false);
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

  Future<void> _confirmBooking() async {
    if (_isGuardian && _selectedPlayerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a player'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final booking = await BookingService.createPrivateBooking(
        coachId: widget.coachId,
        startTime: widget.startTime,
        durationMinutes: widget.durationMinutes,
        paymentMethod: 'test',
        promoCode: _appliedPromoCode,
        playerIds: _isGuardian && _selectedPlayerId != null
            ? [_selectedPlayerId!]
            : null,
      );

      if (mounted) {
        context.push(
          '/booking-success',
          extra: {
            'coachName': widget.coachName,
            'date': DateFormat('EEE, MMM d').format(widget.startTime),
            'time': DateFormat('h:mm a').format(widget.startTime),
            'location': 'Private Session',
            'sessionType': 'Private Session',
            'booking': booking,
            'totalPaid': _totalAmount,
            'paymentMethod': 'Test Booking',
            'confirmationCode':
                booking['_id'] ??
                '#TRX-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
          },
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Booking Failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  void dispose() {
    _promoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('EEE, MMM d').format(widget.startTime);
    final timeStr = DateFormat('h:mm a').format(widget.startTime);
    final endTime = widget.startTime.add(
      Duration(minutes: widget.durationMinutes),
    );
    final endTimeStr = DateFormat('h:mm a').format(endTime);
    final durationLabel = widget.durationMinutes >= 60
        ? '${widget.durationMinutes ~/ 60}hr'
        : '${widget.durationMinutes}min';

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        title: Text(
          'Confirm Booking',
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
                  // Discount Applied Banner
                  if (_appliedPromoCode != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF22C55E),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.check_circle,
                            color: Colors.white,
                            size: 22,
                          ),
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
                                    fontSize: 15,
                                  ),
                                ),
                                Text(
                                  'You\'re saving \$${_discountAmount.toStringAsFixed(2)} on this session.',
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
                    const SizedBox(height: 20),
                  ],

                  // BOOKING SUMMARY
                  Text(
                    'BOOKING SUMMARY',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildBookingSummaryCard(
                    dateStr: dateStr,
                    timeStr: '$timeStr - $endTimeStr',
                  ),

                  const SizedBox(height: 24),

                  // GUARDIAN PLAYER SELECTION
                  if (_isGuardian) ...[
                    Text(
                      'BOOKING FOR',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildPlayerSelection(),
                    const SizedBox(height: 24),
                  ],

                  // PRICE BREAKDOWN
                  Text(
                    'PRICE BREAKDOWN',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildPriceBreakdownCard(durationLabel),

                  const SizedBox(height: 20),

                  // Promo error
                  if (_promoError != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: Colors.red,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _promoError!,
                            style: GoogleFonts.inter(
                              color: Colors.red,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],

                  // PROMO CODE
                  if (_appliedPromoCode != null)
                    _buildAppliedPromoRow()
                  else
                    _buildPromoCodeInput(),

                  const SizedBox(height: 24),

                  // PAYMENT METHOD
                  Text(
                    'PAYMENT METHOD',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildPaymentMethod(),

                  const SizedBox(height: 12),

                  Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.lock_outline,
                          size: 14,
                          color: Colors.grey[500],
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Payments are secure and encrypted',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // PAY TOTAL BUTTON
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
                onPressed: _isProcessing ? null : _confirmBooking,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppPalette.orangeAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: _isProcessing
                    ? const SizedBox(
                        width: 22,
                        height: 22,
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
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '\$ ${_totalAmount.toStringAsFixed(2)}',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
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

  // ─── BOOKING SUMMARY CARD ───
  Widget _buildBookingSummaryCard({
    required String dateStr,
    required String timeStr,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          // Coach row
          Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: AppPalette.navyPrimary.withValues(alpha: 0.1),
                child: Text(
                  widget.coachName.isNotEmpty
                      ? widget.coachName[0].toUpperCase()
                      : 'C',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: AppPalette.navyPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.coachName,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                        color: AppPalette.navyPrimary,
                      ),
                    ),
                    Text(
                      'Cricket Coaching • Private Session',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(
                          Icons.verified,
                          size: 13,
                          color: AppPalette.orangeAccent,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'TOP RATED COACH',
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
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Divider(color: Colors.grey.shade200, height: 1),
          ),

          // Date & Time
          _buildInfoRow(
            Icons.calendar_today_rounded,
            const Color(0xFFFFF3E0),
            AppPalette.orangeAccent,
            'DATE & TIME',
            '$dateStr • $timeStr',
          ),
          const SizedBox(height: 14),
          // Location
          _buildInfoRow(
            Icons.location_on_rounded,
            const Color(0xFFFCE4EC),
            Colors.red.shade400,
            'SESSION TYPE',
            '1-on-1 Private Session (${widget.durationMinutes} min)',
          ),
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
            color: bgColor,
            borderRadius: BorderRadius.circular(10),
          ),
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

  // ─── PLAYER SELECTION ───
  Widget _buildPlayerSelection() {
    if (_isLoadingPlayers) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_players.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.amber.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.amber),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'No players found. Add a player from your profile first.',
                style: GoogleFonts.inter(fontSize: 13, color: Colors.black87),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: _players.map((player) {
          final playerId = player['_id'] as String;
          final isSelected = _selectedPlayerId == playerId;
          return InkWell(
            onTap: () => setState(() => _selectedPlayerId = playerId),
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: AppPalette.orangeAccent.withValues(
                      alpha: 0.15,
                    ),
                    backgroundImage: player['profilePhoto'] != null
                        ? NetworkImage(player['profilePhoto'])
                        : null,
                    child: player['profilePhoto'] == null
                        ? Text(
                            (player['fullName'] ?? 'P')[0].toUpperCase(),
                            style: GoogleFonts.inter(
                              color: AppPalette.orangeAccent,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      player['fullName'] ?? 'Player',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: AppPalette.navyPrimary,
                      ),
                    ),
                  ),
                  Icon(
                    isSelected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    color: isSelected
                        ? AppPalette.orangeAccent
                        : Colors.grey[400],
                    size: 22,
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ─── PRICE BREAKDOWN ───
  Widget _buildPriceBreakdownCard(String durationLabel) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          _buildPriceRow('Session Fee ($durationLabel)', _sessionFee),
          const SizedBox(height: 10),
          _buildPriceRow('Service Fee', _serviceFee),
          const SizedBox(height: 10),
          _buildPriceRow('Tax', _tax),
          if (_appliedPromoCode != null) ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.local_offer,
                      size: 15,
                      color: Color(0xFF22C55E),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Discount ($_appliedPromoCode)',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: const Color(0xFF22C55E),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                Text(
                  '-\$${_discountAmount.toStringAsFixed(2)}',
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
                '\$ ${_totalAmount.toStringAsFixed(2)}',
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppPalette.navyPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, double amount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[600]),
        ),
        Text(
          '\$ ${amount.toStringAsFixed(2)}',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppPalette.navyPrimary,
          ),
        ),
      ],
    );
  }

  // ─── PROMO CODE INPUT ───
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
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
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
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
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

  // ─── APPLIED PROMO ROW ───
  Widget _buildAppliedPromoRow() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFF22C55E).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Color(0xFF22C55E), size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _appliedPromoCode!,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                color: const Color(0xFF22C55E),
                fontSize: 15,
              ),
            ),
          ),
          TextButton(
            onPressed: _removePromoCode,
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
              backgroundColor: Colors.red.withValues(alpha: 0.08),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Remove',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── PAYMENT METHOD ───
  Widget _buildPaymentMethod() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppPalette.orangeAccent, width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.purple.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.developer_mode,
              color: Colors.purple,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Test Booking',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: AppPalette.navyPrimary,
                  ),
                ),
                Text(
                  'No charge applied',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.radio_button_checked,
            color: AppPalette.orangeAccent,
            size: 22,
          ),
        ],
      ),
    );
  }
}
