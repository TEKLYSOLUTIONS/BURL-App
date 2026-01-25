import 'package:flutter/material.dart';
import '../../config/palette.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../services/session_service.dart';
import 'package:intl/intl.dart';

class BookingScreen extends StatefulWidget {
  final String sessionId;

  const BookingScreen({super.key, required this.sessionId});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _session;
  int _selectedDateIndex = 0;
  int _selectedTimeIndex = -1;

  List<DateTime> _availableDates = [];

  @override
  void initState() {
    super.initState();
    _fetchSessionDetails();
  }

  Future<void> _fetchSessionDetails() async {
    try {
      final session = await SessionService.getSessionById(widget.sessionId);

      // Extract available dates from occurrences
      final List<DateTime> dates = [];
      if (session['occurrences'] != null) {
        for (var occurrence in session['occurrences']) {
          final date = DateTime.parse(occurrence['date']);
          if (date.isAfter(DateTime.now())) {
            dates.add(date);
          }
        }
      }

      dates.sort();

      setState(() {
        _session = session;
        _availableDates = dates;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading session: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
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
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_session == null) {
      return Scaffold(
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
        ),
        body: const Center(child: Text('Session not found')),
      );
    }

    final sessionTitle = _session!['title'] ?? 'Session';
    final coachName = _session!['coach']?['fullName'] ?? 'Coach';
    final location = _session!['location'] ?? 'TBA';

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
                      'https://i.pravatar.cc/150?img=12', // Reliable placeholder
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
                          sessionTitle,
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: AppPalette.textPrimaryLight,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'with Coach $coachName',
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
            _availableDates.isEmpty
                ? Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      'No upcoming sessions available',
                      style: GoogleFonts.inter(
                        color: AppPalette.textSecondaryLight,
                      ),
                    ),
                  )
                : SizedBox(
                    height: 80,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _availableDates.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        final date = _availableDates[index];
                        final isSelected = index == _selectedDateIndex;
                        return GestureDetector(
                          onTap: () =>
                              setState(() => _selectedDateIndex = index),
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
                                  DateFormat('EEE').format(date),
                                  style: GoogleFonts.inter(
                                    color: isSelected
                                        ? Colors.white70
                                        : AppPalette.textSecondaryLight,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  DateFormat('d').format(date),
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
            _availableDates.isEmpty
                ? const SizedBox.shrink()
                : Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      GestureDetector(
                        onTap: () => setState(() => _selectedTimeIndex = 0),
                        child: AnimatedContainer(
                          duration: 200.ms,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: _selectedTimeIndex == 0
                                ? AppPalette.orangeAccent
                                : Colors.white,
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: _selectedTimeIndex == 0
                                  ? AppPalette.orangeAccent
                                  : AppPalette.divider,
                            ),
                          ),
                          child: Text(
                            _availableDates.isNotEmpty
                                ? DateFormat(
                                    'h:mm a',
                                  ).format(_availableDates[_selectedDateIndex])
                                : 'Select Date',
                            style: GoogleFonts.inter(
                              color: _selectedTimeIndex == 0
                                  ? Colors.white
                                  : AppPalette.textPrimaryLight,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ).animate().fadeIn(delay: 300.ms),

            const SizedBox(height: 40),

            // Bottom Action
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _availableDates.isEmpty || _selectedTimeIndex == -1
                    ? null
                    : () {
                        final selectedDate =
                            _availableDates[_selectedDateIndex];
                        context.push(
                          '/confirm-booking',
                          extra: {
                            'sessionId': widget.sessionId,
                            'session': _session,
                            'occurrenceDate': selectedDate.toIso8601String(),
                            'date': DateFormat(
                              'EEE, MMM d',
                            ).format(selectedDate),
                            'time': DateFormat('h:mm a').format(selectedDate),
                            'coachName': coachName,
                            'location': location,
                          },
                        );
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
