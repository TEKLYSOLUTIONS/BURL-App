import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../../services/session_service.dart';
import '../../../services/booking_service.dart';

class CalendarTab extends StatefulWidget {
  const CalendarTab({super.key});

  @override
  State<CalendarTab> createState() => _CalendarTabState();
}

class _CalendarTabState extends State<CalendarTab> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<dynamic>> _events = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _fetchCalendarData();
  }

  Future<void> _fetchCalendarData() async {
    setState(() => _isLoading = true);
    try {
      // Fetch both sessions and bookings
      // We'll fetch 'all' to populate the calendar
      // In a real production app, we should probably fetch by month range
      // but provided APIs don't easily support range, so we'll fetch a reasonable limit of 'upcoming' and 'past' if needed
      // or just 'all' with a higher limit.

      final sessionsData = await SessionService.getCoachSessions(
        type: 'all',
        limit: 100, // Fetch enough to populate
      );

      final bookingsData = await BookingService.getCoachBookings(
        type: 'upcoming', // Focus on upcoming for bookings first
        limit: 100,
      );

      // Also fetch past bookings to be thorough if needed, but let's start with upcoming + sessions
      final pastBookingsData = await BookingService.getCoachBookings(
        type: 'past',
        limit: 50,
      );

      final Map<DateTime, List<dynamic>> newEvents = {};

      // 1. Process Group Sessions
      final sessions = sessionsData['sessions'] as List<dynamic>;
      for (var session in sessions) {
        if (session['timeSlots'] != null) {
          for (var slot in session['timeSlots']) {
            if (slot['startTime'] != null) {
              DateTime startTime = DateTime.parse(slot['startTime']).toLocal();
              DateTime dateKey = DateTime(
                startTime.year,
                startTime.month,
                startTime.day,
              );

              if (newEvents[dateKey] == null) newEvents[dateKey] = [];

              // Add session info
              newEvents[dateKey]!.add({
                'type': 'group_session',
                'title': session['title'],
                'startTime': startTime,
                'endTime': DateTime.parse(slot['endTime']).toLocal(),
                'data': session,
              });
            }
          }
        }
      }

      // 2. Process Bookings (1-on-1) - Upcoming
      final bookings = bookingsData['bookings'] as List<dynamic>;
      _processBookings(bookings, newEvents);

      // 3. Process Bookings (1-on-1) - Past
      final pastBookings = pastBookingsData['bookings'] as List<dynamic>;
      _processBookings(pastBookings, newEvents);

      setState(() {
        _events = newEvents;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching calendar data: $e');
      setState(() => _isLoading = false);
    }
  }

  void _processBookings(
    List<dynamic> bookings,
    Map<DateTime, List<dynamic>> events,
  ) {
    for (var booking in bookings) {
      if (booking['occurrenceDate'] != null) {
        DateTime startTime = DateTime.parse(
          booking['occurrenceDate'],
        ).toLocal();
        DateTime dateKey = DateTime(
          startTime.year,
          startTime.month,
          startTime.day,
        );

        if (events[dateKey] == null) events[dateKey] = [];

        // Avoid duplicates if multiple bookings exist for same slot (though logic allows it)
        // For calendar view, we might want to show each booking

        events[dateKey]!.add({
          'type': 'booking',
          'title': '1-on-1: ${booking['player']?['fullName'] ?? 'Player'}',
          'startTime': startTime,
          // Assuming 60 mins if no end time, or calculate from session details if needed
          'endTime': startTime.add(const Duration(minutes: 60)),
          'data': booking,
          'status': booking['status'],
        });
      }
    }
  }

  List<dynamic> _getEventsForDay(DateTime day) {
    final dateKey = DateTime(day.year, day.month, day.day);
    return _events[dateKey] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Card(
          margin: const EdgeInsets.all(16),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
            ),
          ),
          child: TableCalendar(
            firstDay: DateTime.utc(2024, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            calendarFormat: CalendarFormat.month,
            startingDayOfWeek: StartingDayOfWeek.monday,
            headerStyle: HeaderStyle(
              titleCentered: true,
              formatButtonVisible: false,
              titleTextStyle: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            calendarStyle: CalendarStyle(
              selectedDecoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                shape: BoxShape.circle,
              ),
              todayDecoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              markerDecoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                shape: BoxShape.circle,
              ),
            ),
            eventLoader: _getEventsForDay,
            onDaySelected: (selectedDay, focusedDay) {
              if (!isSameDay(_selectedDay, selectedDay)) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              }
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
            },
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _buildEventList(),
        ),
      ],
    );
  }

  Widget _buildEventList() {
    final events = _getEventsForDay(_selectedDay!);

    if (events.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No events for this day',
              style: GoogleFonts.inter(color: Colors.grey[600], fontSize: 16),
            ),
          ],
        ),
      );
    }

    // Sort events by time
    events.sort(
      (a, b) =>
          (a['startTime'] as DateTime).compareTo(b['startTime'] as DateTime),
    );

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        final isBooking = event['type'] == 'booking';
        final startTime = DateFormat('h:mm a').format(event['startTime']);
        final endTime = DateFormat('h:mm a').format(event['endTime']);

        return InkWell(
          onTap: () {
            if (isBooking) {
              // Navigate to booking details (if implemented) or show bottom sheet
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Booking details feature coming soon!'),
                ),
              );
            } else {
              // Navigate to session details
              context.push('/session-details/${event['data']['_id']}');
            }
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
              ),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).shadowColor.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isBooking ? Colors.blue : Colors.purple,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event['title'],
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$startTime - $endTime',
                        style: GoogleFonts.inter(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isBooking)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(
                        event['status'],
                      ).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      (event['status']?.toString() ?? 'UNKNOWN').toUpperCase(),
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: _getStatusColor(event['status']),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'confirmed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      case 'completed':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}
