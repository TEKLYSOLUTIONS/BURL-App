import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/palette.dart';

class SubscriptionResultScreen extends StatelessWidget {
  final bool success;
  final String planName;
  final String billingCycle;
  final String totalPaid;
  final String currency;
  final String? promoCode;
  final double promoDiscount;
  final String? errorMessage;
  final int trialDays;

  const SubscriptionResultScreen({
    super.key,
    required this.success,
    required this.planName,
    required this.billingCycle,
    required this.totalPaid,
    required this.currency,
    this.promoCode,
    this.promoDiscount = 0.0,
    this.errorMessage,
    this.trialDays = 0,
  });

  String get _confirmationCode {
    final ts = DateTime.now().millisecondsSinceEpoch.toString();
    return '#SUB-${ts.substring(ts.length - 8).toUpperCase()}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          success ? 'Subscription Confirmed' : 'Payment Failed',
          style: GoogleFonts.inter(
            color: AppPalette.navyPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppPalette.navyPrimary),
          onPressed: () => _navigateHome(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),

                    // ─── Status Icon ────────────────────────────────────────
                    Container(
                      width: 86,
                      height: 86,
                      decoration: BoxDecoration(
                        color: success
                            ? const Color(0xFF22C55E).withValues(alpha: 0.12)
                            : Colors.red.withValues(alpha: 0.10),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        success
                            ? Icons.check_circle_rounded
                            : Icons.cancel_rounded,
                        color: success
                            ? const Color(0xFF22C55E)
                            : Colors.red.shade400,
                        size: 52,
                      ),
                    )
                        .animate()
                        .scale(
                          duration: 420.ms,
                          curve: Curves.easeOutBack,
                        ),

                    const SizedBox(height: 24),

                    Text(
                      success ? 'You\'re now Pro!' : 'Payment Failed',
                      style: GoogleFonts.inter(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppPalette.navyPrimary,
                      ),
                    ).animate().fadeIn().slideY(begin: 0.2),

                    const SizedBox(height: 10),

                    Text(
                      success
                          ? (trialDays > 0
                              ? 'Your $trialDays-day free trial has started. Enjoy all Pro features!'
                              : 'Your $planName subscription is now active. Unlock your potential!')
                          : (errorMessage ??
                              'Something went wrong with your payment. Please try again.'),
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        color: Colors.grey[600],
                        height: 1.5,
                      ),
                    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),

                    const SizedBox(height: 32),

                    // ─── Subscription Card ───────────────────────────────────
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.grey.shade200),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              children: [
                                // Plan + badge row
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: success
                                            ? AppPalette.navyPrimary
                                            : Colors.grey.shade400,
                                        borderRadius:
                                            BorderRadius.circular(12),
                                      ),
                                      child: const Icon(
                                        Icons.workspace_premium,
                                        color: Colors.white,
                                        size: 22,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: success
                                                  ? AppPalette.orangeAccent
                                                      .withValues(alpha: 0.1)
                                                  : Colors.red
                                                      .withValues(alpha: 0.1),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              success
                                                  ? 'ACTIVE SUBSCRIPTION'
                                                  : 'PAYMENT FAILED',
                                              style: GoogleFonts.inter(
                                                fontSize: 9,
                                                fontWeight: FontWeight.bold,
                                                color: success
                                                    ? AppPalette.orangeAccent
                                                    : Colors.red.shade400,
                                                letterSpacing: 1,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            planName,
                                            style: GoogleFonts.inter(
                                              fontSize: 17,
                                              fontWeight: FontWeight.bold,
                                              color: AppPalette.navyPrimary,
                                            ),
                                          ),
                                          Text(
                                            billingCycle,
                                            style: GoogleFonts.inter(
                                              fontSize: 12,
                                              color: Colors.grey[500],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 18),
                                Divider(
                                    color: Colors.grey.shade200, height: 1),
                                const SizedBox(height: 18),

                                // Billing + promo detail columns
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildDetailColumn(
                                        Icons.calendar_month_rounded,
                                        'BILLING',
                                        billingCycle,
                                        success ? 'Auto-renews' : '—',
                                      ),
                                    ),
                                    Container(
                                        width: 1,
                                        height: 50,
                                        color: Colors.grey.shade200),
                                    Expanded(
                                      child: _buildDetailColumn(
                                        Icons.local_offer_rounded,
                                        'PROMO',
                                        promoCode ?? 'None applied',
                                        promoCode != null
                                            ? '-$currency ${promoDiscount.toStringAsFixed(2)} off'
                                            : '—',
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          // ─── Total Paid ──────────────────────────────────
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8F9FE),
                              border: Border(
                                  top: BorderSide(
                                      color: Colors.grey.shade200)),
                              borderRadius: const BorderRadius.only(
                                bottomLeft: Radius.circular(20),
                                bottomRight: Radius.circular(20),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      success ? 'Total Paid' : 'Amount',
                                      style: GoogleFonts.inter(
                                          fontSize: 12,
                                          color: Colors.grey[500]),
                                    ),
                                    Text(
                                      totalPaid,
                                      style: GoogleFonts.inter(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: AppPalette.navyPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                        color: Colors.grey.shade300),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.developer_mode,
                                        size: 16,
                                        color: Colors.purple.shade400,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Test Payment',
                                        style: GoogleFonts.inter(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                          color: AppPalette.navyPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.15),

                    const SizedBox(height: 28),

                    // ─── Confirmation code (success only) ───────────────────
                    if (success) ...[
                      Text(
                        'CONFIRMATION CODE',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[500],
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () {
                          Clipboard.setData(
                              ClipboardData(text: _confirmationCode));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Confirmation code copied!'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _confirmationCode,
                              style: GoogleFonts.inter(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppPalette.navyPrimary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.copy_rounded,
                                size: 17,
                                color: AppPalette.orangeAccent),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Tap to copy',
                        style: GoogleFonts.inter(
                            fontSize: 12, color: Colors.grey[400]),
                      ),
                    ],

                    // ─── Trial info pill (success + trial) ──────────────────
                    if (success && trialDays > 0) ...[
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 14),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFF7D20), Color(0xFFFF9A56)],
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.card_giftcard,
                                color: Colors.white),
                            const SizedBox(width: 10),
                            Text(
                              '$trialDays-day free trial — no charge today',
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(delay: 600.ms),
                    ],

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),

            // ─── Bottom Buttons ─────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
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
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () => success
                          ? _navigateToSettings(context)
                          : _retryPayment(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: success
                            ? AppPalette.orangeAccent
                            : Colors.red.shade400,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      child: Text(
                        success ? 'View My Subscription' : 'Try Again',
                        style: GoogleFonts.inter(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ).animate().fadeIn(delay: 600.ms),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton(
                      onPressed: () => _navigateHome(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppPalette.navyPrimary,
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text(
                        'Back to Home',
                        style: GoogleFonts.inter(
                            fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ).animate().fadeIn(delay: 700.ms),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Helpers ────────────────────────────────────────────────────────────────

  Widget _buildDetailColumn(
    IconData icon,
    String label,
    String line1,
    String line2,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: AppPalette.orangeAccent),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[500],
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            line1,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppPalette.navyPrimary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            line2,
            style: GoogleFonts.inter(
                fontSize: 11, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Future<void> _navigateHome(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final role = prefs.getString('user_role') ?? 'coach';
    if (context.mounted) {
      context.go('/$role/home');
    }
  }

  Future<void> _navigateToSettings(BuildContext context) async {
    if (context.mounted) {
      context.go('/settings');
    }
  }

  void _retryPayment(BuildContext context) {
    // Pop back to the payment screen so user can try again
    Navigator.of(context).pop();
  }
}
