import 'package:flutter/material.dart';
import '../../config/palette.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  int _selectedDateIndex = 0;
  int _selectedTimeIndex = -1;

  final List<String> _dates = [
    'Mon, 12',
    'Tue, 13',
    'Wed, 14',
    'Thu, 15',
    'Fri, 16',
    'Sat, 17',
  ];
  final List<String> _times = [
    '09:00 AM',
    '10:00 AM',
    '11:00 AM',
    '02:00 PM',
    '03:00 PM',
    '04:00 PM',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Book Session',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            color: AppPalette.navyPrimary,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: AppPalette.navyPrimary,
          ),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Coach/Service Info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      'https://images.unsplash.com/photo-1531415074968-036ba1b575da?auto=format&fit=crop&q=80',
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 80,
                        height: 80,
                        color: Colors.grey[300],
                        child: Icon(
                          Icons.broken_image,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Advanced Batting',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: AppPalette.textPrimaryLight,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'with Coach Rahul D.',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: AppPalette.textSecondaryLight,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(
                              Icons.star,
                              size: 16,
                              color: AppPalette.warning,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '4.9 (120+ Sessions)',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppPalette.textPrimaryLight,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn().slideY(begin: 0.1),

            const SizedBox(height: 32),

            Text(
              'Select Date',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppPalette.navyPrimary,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 80,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _dates.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final isSelected = index == _selectedDateIndex;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedDateIndex = index),
                    child: AnimatedContainer(
                      duration: 300.ms,
                      width: 70,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppPalette.navyPrimary
                            : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? AppPalette.navyPrimary
                              : AppPalette.divider,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _dates[index].split(', ')[0],
                            style: GoogleFonts.inter(
                              color: isSelected
                                  ? Colors.white70
                                  : AppPalette.textSecondaryLight,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _dates[index].split(', ')[1],
                            style: GoogleFonts.outfit(
                              color: isSelected
                                  ? Colors.white
                                  : AppPalette.textPrimaryLight,
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ).animate().fadeIn(delay: 200.ms),

            const SizedBox(height: 24),

            Text(
              'Available Slots',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppPalette.navyPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: List.generate(_times.length, (index) {
                final isSelected = index == _selectedTimeIndex;
                return GestureDetector(
                  onTap: () => setState(() => _selectedTimeIndex = index),
                  child: AnimatedContainer(
                    duration: 200.ms,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppPalette.orangeAccent
                          : Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: isSelected
                            ? AppPalette.orangeAccent
                            : AppPalette.divider,
                      ),
                    ),
                    child: Text(
                      _times[index],
                      style: GoogleFonts.inter(
                        color: isSelected
                            ? Colors.white
                            : AppPalette.textPrimaryLight,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              }),
            ).animate().fadeIn(delay: 300.ms),

            const SizedBox(height: 40),

            // Bottom Action
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  // Navigate or confirm
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppPalette.navyPrimary,
                  foregroundColor: Colors.white,
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  'Confirm Booking',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.2),
          ],
        ),
      ),
    );
  }
}
