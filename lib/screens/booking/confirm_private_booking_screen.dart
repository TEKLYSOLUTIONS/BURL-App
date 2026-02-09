import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../config/palette.dart';
import '../../services/booking_service.dart';
import '../../services/auth_service.dart';
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
    required this.durationMinutes,
    required this.price,
  });

  @override
  State<ConfirmPrivateBookingScreen> createState() =>
      _ConfirmPrivateBookingScreenState();
}

class _ConfirmPrivateBookingScreenState
    extends State<ConfirmPrivateBookingScreen> {
  bool _isProcessing = false;
  String _paymentMethod = 'card'; // Default
  String? _promoCode;

  // Guardian specific
  bool _isGuardian = false;
  List<dynamic> _players = [];
  final List<String> _selectedPlayerIds = [];
  bool _isLoadingPlayers = false;

  @override
  void initState() {
    super.initState();
    _checkRoleAndFetchPlayers();
  }

  Future<void> _checkRoleAndFetchPlayers() async {
    final role = await AuthService.getUserRole();
    if (role == 'guardian') {
      setState(() {
        _isGuardian = true;
        _isLoadingPlayers = true;
      });
      try {
        final players = await GuardianService().getMyPlayers();
        if (mounted) {
          setState(() {
            _players = players;
            _isLoadingPlayers = false;
          });
        }
      } catch (e) {
        debugPrint('Error fetching players: $e');
        if (mounted) {
          setState(() => _isLoadingPlayers = false);
        }
      }
    }
  }

  // Calculate totals
  double get _serviceFee => 2.50;
  double get _tax => 0.00;

  // Multiply price by number of players if guardian and players selected
  double get _basePrice {
    if (_isGuardian && _selectedPlayerIds.isNotEmpty) {
      return widget.price * _selectedPlayerIds.length;
    }
    // If guardian but no players selected (validation will catch this), or if player
    // For display purposes, show single price if nothing selected
    return widget.price;
  }

  double get _total => _basePrice + _serviceFee + _tax;

  Future<void> _confirmBooking() async {
    // Validation for guardian
    if (_isGuardian && _selectedPlayerIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one player'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      await BookingService.createPrivateBooking(
        coachId: widget.coachId,
        startTime: widget.startTime,
        durationMinutes: widget.durationMinutes,
        paymentMethod: _paymentMethod,
        promoCode: _promoCode,
        playerIds: _isGuardian ? _selectedPlayerIds : null,
      );

      if (mounted) {
        // Navigate to Success Screen or back to Home
        // Ideally show a success dialog or screen
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Booking Confirmed!'),
            backgroundColor: Colors.green,
          ),
        );
        context.go('/guardian/home'); // Adjusted for guardian/player
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
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPalette.offWhite,
      appBar: AppBar(
        title: Text(
          "Confirm Booking",
          style: GoogleFonts.outfit(
            color: AppPalette.navyPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: BackButton(
          color: AppPalette.navyPrimary,
          onPressed: () => context.pop(),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Session Summary Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: AppPalette.navyPrimary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.person,
                          color: AppPalette.navyPrimary,
                          size: 30,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.coachName,
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: AppPalette.navyPrimary,
                            ),
                          ),
                          Text(
                            "1-on-1 Session",
                            style: GoogleFonts.inter(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Divider(height: 32),
                  _buildRow(
                    "Date",
                    DateFormat('MMM d, yyyy').format(widget.startTime),
                  ),
                  const SizedBox(height: 12),
                  _buildRow(
                    "Time",
                    DateFormat('h:mm a').format(widget.startTime),
                  ),
                  const SizedBox(height: 12),
                  _buildRow("Duration", "${widget.durationMinutes} mins"),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Guardian: Player Selection
            if (_isGuardian) ...[
              Text(
                "Who is this for?",
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppPalette.navyPrimary,
                ),
              ),
              const SizedBox(height: 12),
              if (_isLoadingPlayers)
                const Center(child: CircularProgressIndicator())
              else if (_players.isEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.amber,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          "You haven't added any players yet. Please add players from your profile first.",
                          style: GoogleFonts.inter(color: Colors.black87),
                        ),
                      ),
                    ],
                  ),
                )
              else
                ..._players.map((player) {
                  final isSelected = _selectedPlayerIds.contains(player['_id']);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: CheckboxListTile(
                      value: isSelected,
                      onChanged: (val) {
                        setState(() {
                          if (val == true) {
                            _selectedPlayerIds.add(player['_id']);
                          } else {
                            _selectedPlayerIds.remove(player['_id']);
                          }
                        });
                      },
                      title: Text(
                        player['fullName'],
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          color: AppPalette.navyPrimary,
                        ),
                      ),
                      subtitle: Text(
                        "${player['role']} • ${player['age']} yrs",
                        style: GoogleFonts.inter(fontSize: 12),
                      ),
                      secondary: CircleAvatar(
                        backgroundColor: AppPalette.orangeAccent.withValues(
                          alpha: 0.2,
                        ),
                        child: Text(
                          player['fullName'][0],
                          style: GoogleFonts.outfit(
                            color: AppPalette.orangeAccent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: isSelected
                              ? AppPalette.orangeAccent
                              : Colors.grey[300]!,
                        ),
                      ),
                      activeColor: AppPalette.orangeAccent,
                      tileColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                    ),
                  );
                }),
              const SizedBox(height: 24),
            ],

            // Payment Method (Simplified)
            Text(
              "Payment Method",
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppPalette.navyPrimary,
              ),
            ),
            const SizedBox(height: 16),
            _buildPaymentOption(
              value: 'card',
              label: "Visa ending in 4242",
              icon: Icons.credit_card,
            ),
            const SizedBox(height: 8),
            _buildPaymentOption(
              value: 'test',
              label: "Test Booking (No Charge)",
              icon: Icons.developer_mode,
              iconColor: Colors.purple,
            ),

            const SizedBox(height: 24),

            // Price Breakdown
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                children: [
                  _buildRow(
                    "Rate per person",
                    "\$${widget.price.toStringAsFixed(2)}",
                  ),
                  if (_isGuardian && _selectedPlayerIds.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: _buildRow(
                        "Players",
                        "x ${_selectedPlayerIds.length}",
                        valueColor: AppPalette.orangeAccent,
                      ),
                    ),
                  const SizedBox(height: 12),
                  _buildRow(
                    "Session Fee",
                    "\$${_basePrice.toStringAsFixed(2)}",
                  ),
                  const SizedBox(height: 12),
                  _buildRow(
                    "Service Fee",
                    "\$${_serviceFee.toStringAsFixed(2)}",
                  ),
                  const Divider(height: 32),
                  _buildRow(
                    "Total",
                    "\$${_total.toStringAsFixed(2)}",
                    isBold: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: _isProcessing ? null : _confirmBooking,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppPalette.orangeAccent,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 0,
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
              : Text(
                  _isGuardian && _selectedPlayerIds.isEmpty
                      ? 'Select Players'
                      : 'Confirm & Pay \$${_total.toStringAsFixed(2)}',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildPaymentOption({
    required String value,
    required String label,
    required IconData icon,
    Color? iconColor,
  }) {
    final isSelected = _paymentMethod == value;

    return InkWell(
      onTap: () => setState(() => _paymentMethod = value),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppPalette.orangeAccent : Colors.grey[200]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor ?? AppPalette.navyPrimary),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? AppPalette.navyPrimary : Colors.black,
                ),
              ),
            ),
            Icon(
              isSelected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: isSelected ? AppPalette.orangeAccent : Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(
    String label,
    String value, {
    bool isBold = false,
    Color? valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            color: isBold ? AppPalette.navyPrimary : Colors.grey[600],
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            fontSize: isBold ? 16 : 14,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.outfit(
            color: valueColor ?? AppPalette.navyPrimary,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            fontSize: isBold ? 18 : 14,
          ),
        ),
      ],
    );
  }
}
