import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../config/palette.dart';
import '../../services/search_service.dart';
import '../../services/profile_service.dart';

class CoachBookingScreen extends StatefulWidget {
  final String coachId;
  final String coachName; // Pass name for UI
  final String? coachImageUrl; // Pass image for UI
  final double hourlyRate;
  final int sessionDuration;
  final String cancellationPolicy;

  const CoachBookingScreen({
    super.key,
    required this.coachId,
    required this.coachName,
    this.coachImageUrl,
    required this.hourlyRate,
    this.sessionDuration = 60,
    this.cancellationPolicy = 'flexible',
  });

  @override
  State<CoachBookingScreen> createState() => _CoachBookingScreenState();
}

class _CoachBookingScreenState extends State<CoachBookingScreen> {
  final SearchService _searchService = SearchService();

  final CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  // Available slots logic
  // Map<DateTime, List<Map<String, dynamic>>> _availableSlots = {};
  // API returns list of { startTime, endTime }.
  List<dynamic> _availability = [];
  bool _isLoading = false;

  Map<String, dynamic>? _selectedSlot;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _fetchAvailability();
  }

  Future<void> _fetchAvailability() async {
    setState(() => _isLoading = true);
    try {
      // Fetch for the current focused month
      // Start from first day of month
      final start = DateTime(_focusedDay.year, _focusedDay.month, 1);
      // End at last day of month
      final end = DateTime(_focusedDay.year, _focusedDay.month + 1, 0);

      final data = await _searchService.getCoachAvailability(
        coachId: widget.coachId,
        startDate: start,
        endDate: end,
      );

      setState(() {
        _availability = data;
        _isLoading = false;
        // Reset selection if not in new availability?
        _selectedSlot = null;
      });
    } catch (e) {
      debugPrint('Error fetching availability: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load availability: $e')),
        );
      }
    }
  }

  // Get slots for a specific day
  List<dynamic> _getSlotsForDay(DateTime day) {
    return _availability.where((slot) {
      final slotStart = DateTime.parse(slot['startTime']).toLocal();
      return isSameDay(slotStart, day);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    // Current day slots
    final daySlots = _selectedDay != null ? _getSlotsForDay(_selectedDay!) : [];

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          "Book Session",
          style: GoogleFonts.inter(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: BackButton(color: Theme.of(context).colorScheme.onSurface),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Coach Info
                    Text(
                      "Book a session with ${widget.coachName}",
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Select a date and time for your 1-on-1 session.",
                      style: GoogleFonts.inter(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.6),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Calendar
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(context)
                                .shadowColor
                                .withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        border: Border.all(
                          color: Theme.of(context)
                              .dividerColor
                              .withValues(alpha: 0.1),
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 8,
                      ),
                      child: TableCalendar(
                        firstDay: DateTime.now(),
                        lastDay: DateTime.now().add(const Duration(days: 90)),
                        focusedDay: _focusedDay,
                        calendarFormat: _calendarFormat,
                        selectedDayPredicate: (day) {
                          return isSameDay(_selectedDay, day);
                        },
                        onDaySelected: (selectedDay, focusedDay) {
                          if (!isSameDay(_selectedDay, selectedDay)) {
                            setState(() {
                              _selectedDay = selectedDay;
                              _focusedDay = focusedDay;
                              _selectedSlot = null; // Clear slot selection
                            });
                          }
                        },
                        onPageChanged: (focusedDay) {
                          _focusedDay = focusedDay;
                          _fetchAvailability(); // Refetch for new month
                        },
                        daysOfWeekStyle: DaysOfWeekStyle(
                          weekdayStyle: GoogleFonts.inter(
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                          weekendStyle: GoogleFonts.inter(
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        calendarStyle: CalendarStyle(
                          defaultTextStyle: GoogleFonts.inter(
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                          weekendTextStyle: GoogleFonts.inter(
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                          outsideTextStyle: GoogleFonts.inter(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.4),
                          ),
                          selectedDecoration: const BoxDecoration(
                            color: AppPalette.orangeAccent,
                            shape: BoxShape.circle,
                          ),
                          todayDecoration: BoxDecoration(
                            color: AppPalette.orangeAccent.withValues(
                              alpha: 0.3,
                            ),
                            shape: BoxShape.circle,
                          ),
                          markerDecoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                        headerStyle: HeaderStyle(
                          formatButtonVisible: false,
                          titleCentered: true,
                          titleTextStyle: GoogleFonts.inter(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                          leftChevronIcon: Icon(
                            Icons.chevron_left,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                          rightChevronIcon: Icon(
                            Icons.chevron_right,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        eventLoader: (day) {
                          return _getSlotsForDay(day);
                        },
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Time Slots
                    if (_selectedDay != null) ...[
                      Text(
                        "Available Slots (${DateFormat('MMM d').format(_selectedDay!)})",
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (_isLoading)
                        const Center(child: CircularProgressIndicator())
                      else if (daySlots.isEmpty)
                        Text(
                          "No slots available for this date.",
                          style: GoogleFonts.inter(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.6)),
                        )
                      else
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: daySlots.map((slot) {
                            final startTime = DateTime.parse(
                              slot['startTime'],
                            ).toLocal();
                            final timeStr = DateFormat(
                              'h:mm a',
                            ).format(startTime);
                            final isSelected = _selectedSlot == slot;

                            return InkWell(
                              onTap: () {
                                setState(() {
                                  _selectedSlot = slot;
                                });
                              },
                              borderRadius: BorderRadius.circular(30),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppPalette.orangeAccent
                                      : Theme.of(context).cardColor,
                                  borderRadius: BorderRadius.circular(30),
                                  border: Border.all(
                                    color: isSelected
                                        ? AppPalette.orangeAccent
                                        : Theme.of(context)
                                            .dividerColor
                                            .withValues(alpha: 0.2),
                                  ),
                                ),
                                child: Text(
                                  timeStr,
                                  style: GoogleFonts.inter(
                                    color: isSelected
                                        ? Colors.white
                                        : Theme.of(context)
                                            .colorScheme
                                            .onSurface,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                    ],
                  ],
                ),
              ),
            ),

            // Bottom Bar
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                boxShadow: [
                  BoxShadow(
                    color:
                        Theme.of(context).shadowColor.withValues(alpha: 0.05),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
                border: Border(
                  top: BorderSide(
                      color: Theme.of(context)
                          .dividerColor
                          .withValues(alpha: 0.1)),
                ),
              ),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Total Price',
                        style: GoogleFonts.inter(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.6),
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        '\$ ${(widget.hourlyRate * (widget.sessionDuration / 60.0)).toStringAsFixed(0)}',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _selectedSlot != null
                          ? () async {
                              final ScaffoldMessengerState messenger =
                                  ScaffoldMessenger.of(context);
                              final dynamic localRouter = GoRouter.of(context);
                              final isComplete =
                                  await ProfileService.isProfileComplete();
                              if (!mounted) return;
                              if (!isComplete) {
                                messenger.showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        'Please complete your profile (Location and Phone Number) before booking.'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                return;
                              }

                              final startTime = DateTime.parse(
                                _selectedSlot!['startTime'],
                              ).toLocal();

                              localRouter.push(
                                '/booking/confirm-private',
                                extra: <String, dynamic>{
                                  'coachId': widget.coachId,
                                  'coachName': widget.coachName,
                                  'coachImageUrl': widget.coachImageUrl,
                                  'startTime': startTime,
                                  'durationMinutes': widget.sessionDuration,
                                  'price': widget.hourlyRate *
                                      (widget.sessionDuration / 60.0),
                                  'cancellationPolicy':
                                      widget.cancellationPolicy,
                                },
                              );
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppPalette.orangeAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Continue', // "Confirm" or "Book"
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
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
}
