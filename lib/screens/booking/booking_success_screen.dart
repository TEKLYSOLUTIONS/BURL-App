import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../config/palette.dart';

class BookingSuccessScreen extends StatelessWidget {
  final Map<String, dynamic> bookingDetails;

  const BookingSuccessScreen({super.key, this.bookingDetails = const {}});

  @override
  Widget build(BuildContext context) {
    // Defaults matching confirm screen
    final coachName = bookingDetails['coachName'] ?? 'Michael Ray';
    final coachImage =
        bookingDetails['coachImage'] ?? 'https://i.pravatar.cc/150?img=12';
    final dateStr = bookingDetails['date'] ?? 'Tue, Oct 24';
    final timeStr = bookingDetails['time'] ?? '10:00 AM';
    final location = bookingDetails['location'] ?? 'Sunnydale Sports Complex';

    // In a real app we'd get these from the backend or calculation
    final totalPaid = '\$62.50';
    final confirmationCode = '#TRX - 88592';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Confirmation',
          style: GoogleFonts.outfit(
            color: AppPalette.navyPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppPalette.navyPrimary),
          onPressed: () => context.go('/player/home'), // Go home on close
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: AppPalette.navyPrimary),
            onPressed: () {},
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              // Success Icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFF22C55E).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: Color(0xFF22C55E),
                  size: 48,
                ),
              ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),

              const SizedBox(height: 24),

              Text(
                'Booking Confirmed!',
                style: GoogleFonts.outfit(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppPalette.navyPrimary,
                ),
              ).animate().fadeIn().slideY(begin: 0.2),

              const SizedBox(height: 12),

              Text(
                'You\'re all set! Your spot on the court is reserved.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: AppPalette.textSecondaryLight,
                  height: 1.5,
                ),
              ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),

              const SizedBox(height: 40),

              // Booking Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                  border: Border.all(color: Colors.grey[100]!),
                ),
                child: Column(
                  children: [
                    // Upcoming Session Tag
                    Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            coachImage,
                            width: 40,
                            height: 40,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                                  color: Colors.grey,
                                  width: 40,
                                  height: 40,
                                ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'UPCOMING SESSION',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: AppPalette.orangeAccent,
                                  letterSpacing: 1,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Elite Tennis Coaching',
                                style: GoogleFonts.outfit(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppPalette.navyPrimary,
                                ),
                              ),
                              Text(
                                'Coach $coachName',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: AppPalette.textSecondaryLight,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Divider(height: 1),
                    const SizedBox(height: 20),

                    // Date & Time
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppPalette.orangeAccent.withValues(
                              alpha: 0.1,
                            ),
                            borderRadius: BorderRadius.circular(10),
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
                                  fontWeight: FontWeight.bold,
                                  color: AppPalette.textSecondaryLight,
                                ),
                              ),
                              Text(
                                '$dateStr • $timeStr',
                                style: GoogleFonts.outfit(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: AppPalette.navyPrimary,
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
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppPalette.orangeAccent.withValues(
                              alpha: 0.1,
                            ),
                            borderRadius: BorderRadius.circular(10),
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
                                  fontWeight: FontWeight.bold,
                                  color: AppPalette.textSecondaryLight,
                                ),
                              ),
                              Text(
                                location,
                                style: GoogleFonts.outfit(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: AppPalette.navyPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(16),
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
                                  color: AppPalette.textSecondaryLight,
                                ),
                              ),
                              Text(
                                totalPaid,
                                style: GoogleFonts.outfit(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: AppPalette.navyPrimary,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              const Icon(Icons.apple, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Apple Pay',
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.bold,
                                  color: AppPalette.navyPrimary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2),

              const SizedBox(height: 24),

              Text(
                'CONFIRMATION CODE',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppPalette.textSecondaryLight,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    confirmationCode,
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppPalette.navyPrimary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.copy, size: 16, color: Colors.grey),
                ],
              ),

              const SizedBox(height: 48),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    // Navigate to details or sessions
                    context.go('/player/sessions');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppPalette.orangeAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                  ),
                  child: Text(
                    'View Booking Details',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ).animate().fadeIn(delay: 600.ms),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => context.go('/player/home'),
                child: Text(
                  'Back to Home',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    color: AppPalette.navyPrimary,
                  ),
                ),
              ).animate().fadeIn(delay: 700.ms),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
