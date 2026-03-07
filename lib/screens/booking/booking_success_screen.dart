import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/palette.dart';

class BookingSuccessScreen extends StatelessWidget {
  final Map<String, dynamic> bookingDetails;

  const BookingSuccessScreen({super.key, this.bookingDetails = const {}});

  @override
  Widget build(BuildContext context) {
    final coachName = bookingDetails['coachName'] ?? 'Coach';
    final dateStr = bookingDetails['date'] ?? 'Date TBD';
    final timeStr = bookingDetails['time'] ?? 'Time TBD';
    final location = bookingDetails['location'] ?? 'Location TBD';
    final sessionType = bookingDetails['sessionType'] ?? 'Session';
    final paymentMethod = bookingDetails['paymentMethod'] ?? 'Test Booking';

    // Get session title
    final session = bookingDetails['session'];
    final sessionTitle = session is Map<String, dynamic>
        ? (session['title'] ?? 'Cricket Coaching')
        : 'Cricket Coaching';

    // Get real total and confirmation code
    final totalPaid = bookingDetails['totalPaid'];
    final totalStr = totalPaid is num
        ? '\$ ${totalPaid.toStringAsFixed(2)}'
        : '\$ 62.50';

    final rawCode = bookingDetails['confirmationCode'] ?? '';
    final confirmationCode = rawCode.toString().length > 8
        ? '#${rawCode.toString().substring(rawCode.toString().length - 8).toUpperCase()}'
        : '#TRX-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Confirmation',
          style: GoogleFonts.inter(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.close, color: colorScheme.onSurface),
          onPressed: () => _navigateHome(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: AppPalette.orangeAccent),
            onPressed: () {},
          ),
        ],
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
                    // Success Icon
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: const Color(0xFF22C55E).withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_circle_rounded,
                        color: Color(0xFF22C55E),
                        size: 50,
                      ),
                    ).animate().scale(
                      duration: 400.ms,
                      curve: Curves.easeOutBack,
                    ),

                    const SizedBox(height: 24),

                    Text(
                      'Booking Confirmed!',
                      style: GoogleFonts.inter(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppPalette.navyPrimary,
                      ),
                    ).animate().fadeIn().slideY(begin: 0.2),

                    const SizedBox(height: 10),

                    Text(
                      'You\'re all set! Your spot on the court is reserved.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        color: colorScheme.onSurface.withValues(alpha: 0.6),
                        height: 1.5,
                      ),
                    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),

                    const SizedBox(height: 32),

                    // Booking Card
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.25)),
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
                                // Coach + session info
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 24,
                                        backgroundColor: colorScheme.onSurface
                                            .withValues(alpha: 0.1),
                                        child: Text(
                                          coachName.isNotEmpty
                                              ? coachName[0].toUpperCase()
                                              : 'C',
                                          style: GoogleFonts.inter(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                            color: colorScheme.onSurface,
                                        ),
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
                                              horizontal: 8,
                                              vertical: 3,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppPalette.orangeAccent
                                                  .withValues(alpha: 0.1),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              'UPCOMING SESSION',
                                              style: GoogleFonts.inter(
                                                fontSize: 9,
                                                fontWeight: FontWeight.bold,
                                                color: AppPalette.orangeAccent,
                                                letterSpacing: 1,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            sessionTitle,
                                            style: GoogleFonts.inter(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: colorScheme.onSurface,
                                            ),
                                          ),
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.person_outline,
                                                size: 13,
                                                color: colorScheme.onSurface.withValues(alpha: 0.5),
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                'Coach $coachName',
                                                style: GoogleFonts.inter(
                                                  fontSize: 12,
                                                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 18),
                                Divider(color: colorScheme.outline.withValues(alpha: 0.25), height: 1),
                                const SizedBox(height: 18),

                                // Date & Time + Location
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildDetailColumn(
                                        context,
                                        Icons.calendar_today_rounded,
                                        'DATE & TIME',
                                        dateStr,
                                        timeStr,
                                      ),
                                    ),
                                    Container(
                                      width: 1,
                                      height: 50,
                                      color: colorScheme.outline.withValues(alpha: 0.25),
                                    ),
                                    Expanded(
                                      child: _buildDetailColumn(
                                        context,
                                        Icons.location_on_rounded,
                                        'LOCATION',
                                        location,
                                        sessionType,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          // Total Paid section
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context).scaffoldBackgroundColor,
                              border: Border(
                                top: BorderSide(color: colorScheme.outline.withValues(alpha: 0.25)),
                              ),
                              borderRadius: const BorderRadius.only(
                                bottomLeft: Radius.circular(20),
                                bottomRight: Radius.circular(20),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Total Paid',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: colorScheme.onSurface.withValues(alpha: 0.5),
                                      ),
                                    ),
                                    Text(
                                      totalStr,
                                      style: GoogleFonts.inter(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: colorScheme.onSurface,
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: colorScheme.outline.withValues(alpha: 0.4),
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.credit_card,
                                        size: 16,
                                        color: colorScheme.onSurface,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        paymentMethod,
                                        style: GoogleFonts.inter(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                          color: colorScheme.onSurface,
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

                    // Confirmation Code
                    Text(
                      'CONFIRMATION CODE',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface.withValues(alpha: 0.5),
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () {
                        Clipboard.setData(
                          ClipboardData(text: confirmationCode),
                        );
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
                            confirmationCode,
                            style: GoogleFonts.inter(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.copy_rounded,
                            size: 17,
                            color: AppPalette.orangeAccent,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),

            // Bottom buttons
            Container(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              decoration: BoxDecoration(
                color: colorScheme.surface,
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
                      onPressed: () {
                        _navigateToBookings(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppPalette.orangeAccent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'View Booking Details',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
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
                        foregroundColor: colorScheme.onSurface,
                        side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.4)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        'Back to Home',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
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

  Widget _buildDetailColumn(
    BuildContext context,
    IconData icon,
    String label,
    String line1,
    String line2,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
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
                  color: colorScheme.onSurface.withValues(alpha: 0.5),
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
              color: colorScheme.onSurface,
            ),
          ),
          Text(
            line2,
            style: GoogleFonts.inter(fontSize: 11, color: colorScheme.onSurface.withValues(alpha: 0.5)),
          ),
        ],
      ),
    );
  }

  Future<void> _navigateHome(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final role = prefs.getString('user_role') ?? 'player';
    if (context.mounted) {
      context.go('/$role/home');
    }
  }

  Future<void> _navigateToBookings(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final role = prefs.getString('user_role') ?? 'player';
    if (context.mounted) {
      context.go('/$role/sessions');
    }
  }
}
